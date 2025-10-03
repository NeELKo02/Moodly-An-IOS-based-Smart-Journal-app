import pandas as pd
import numpy as np
import re
import os
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier, VotingClassifier, StackingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.neural_network import MLPClassifier
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import StandardScaler
from sklearn.feature_extraction.text import TfidfVectorizer
import joblib
from tqdm import tqdm
import warnings
warnings.filterwarnings('ignore')

class AdvancedEnsembleModel:
    def __init__(self):
        self.glove_embeddings = {}
        self.embedding_dim = 100
        self.ensemble_model = None
        self.scaler = StandardScaler()
        self.tfidf_vectorizer = None
        self.best_accuracy = 0
        
    def load_glove_embeddings(self):
        """Load GloVe embeddings"""
        print("🔄 Loading GloVe embeddings...")
        
        glove_file = "glove.6B.100d.txt"
        
        with open(glove_file, 'r', encoding='utf-8') as f:
            for line in tqdm(f, desc="Loading", total=400000):
                values = line.split()
                word = values[0]
                vector = np.array(values[1:], dtype='float32')
                self.glove_embeddings[word] = vector
                
                if len(self.glove_embeddings) >= 50000:
                    break
        
        print(f"✅ Loaded {len(self.glove_embeddings)} word embeddings!")
        return self.glove_embeddings
    
    def advanced_preprocess_text(self, text):
        """Advanced text preprocessing"""
        if pd.isna(text):
            return ""
        
        text = str(text).lower()
        
        # Remove URLs, mentions, hashtags
        text = re.sub(r'http\S+|www\S+|https\S+', '', text, flags=re.MULTILINE)
        text = re.sub(r'@\w+|#\w+', '', text)
        
        # Keep important punctuation for sentiment
        text = re.sub(r'[^a-zA-Z\s.,!?]', '', text)
        
        # Remove extra whitespace
        text = re.sub(r'\s+', ' ', text).strip()
        
        return text
    
    def text_to_glove_vector(self, text, max_length=50):
        """Enhanced GloVe vectorization"""
        words = text.split()[:max_length]
        
        embedding_vector = np.zeros(self.embedding_dim)
        word_count = 0
        
        for word in words:
            if word in self.glove_embeddings:
                embedding_vector += self.glove_embeddings[word]
                word_count += 1
            else:
                word_lower = word.lower()
                if word_lower in self.glove_embeddings:
                    embedding_vector += self.glove_embeddings[word_lower]
                    word_count += 1
        
        if word_count > 0:
            embedding_vector /= word_count
        
        return embedding_vector
    
    def extract_advanced_features(self, texts):
        """Extract advanced text features"""
        features = []
        
        for text in texts:
            # Basic features
            text_length = len(text)
            word_count = len(text.split())
            
            # Sentiment indicators
            exclamation_count = text.count('!')
            question_count = text.count('?')
            period_count = text.count('.')
            comma_count = text.count(',')
            
            # Emotional indicators
            uppercase_ratio = len([c for c in text if c.isupper()]) / max(len(text), 1)
            space_ratio = text.count(' ') / max(len(text), 1)
            
            # Word-level features
            words = text.split()
            avg_word_length = np.mean([len(word) for word in words]) if words else 0
            
            # Sentiment-specific words
            positive_words = ['good', 'great', 'excellent', 'amazing', 'wonderful', 'fantastic', 'love', 'happy', 'joy', 'smile']
            negative_words = ['bad', 'terrible', 'awful', 'horrible', 'hate', 'sad', 'angry', 'frustrated', 'disappointed']
            neutral_words = ['okay', 'fine', 'normal', 'average', 'regular', 'standard']
            
            positive_count = sum(1 for word in words if word.lower() in positive_words)
            negative_count = sum(1 for word in words if word.lower() in negative_words)
            neutral_count = sum(1 for word in words if word.lower() in neutral_words)
            
            # Punctuation patterns
            multiple_exclamation = text.count('!!')
            multiple_question = text.count('??')
            
            text_features = [
                text_length,
                word_count,
                exclamation_count,
                question_count,
                period_count,
                comma_count,
                uppercase_ratio,
                space_ratio,
                avg_word_length,
                positive_count,
                negative_count,
                neutral_count,
                multiple_exclamation,
                multiple_question
            ]
            features.append(text_features)
        
        return np.array(features)
    
    def load_emotion_dataset(self):
        """Load emotion dataset with data augmentation"""
        print("📊 Loading emotion dataset...")
        
        df = pd.read_csv("Emotion_final.csv")
        print(f"✅ Loaded {len(df)} samples")
        
        # Map emotions to sentiment
        emotion_to_sentiment = {
            'happy': 'positive',
            'love': 'positive', 
            'surprise': 'neutral',
            'anger': 'negative',
            'sadness': 'negative',
            'fear': 'negative'
        }
        
        df['sentiment'] = df['Emotion'].map(emotion_to_sentiment)
        df = df.dropna(subset=['Text', 'sentiment'])
        df['text'] = df['Text'].apply(self.advanced_preprocess_text)
        df = df[df['text'].str.len() > 10]
        
        # Use more data for better training
        if len(df) > 12000:
            df = df.sample(n=12000, random_state=42)
        
        print(f"📊 Final dataset: {len(df)} samples")
        print(f"📊 Sentiment distribution:")
        print(df['sentiment'].value_counts())
        
        return df['text'].values, df['sentiment'].values
    
    def prepare_advanced_features(self, texts):
        """Prepare comprehensive feature set"""
        print("🔄 Preparing advanced features...")
        
        # GloVe embeddings
        glove_features = []
        for text in tqdm(texts, desc="GloVe processing"):
            glove_vector = self.text_to_glove_vector(text)
            glove_features.append(glove_vector)
        glove_features = np.array(glove_features)
        
        # TF-IDF features with different n-grams
        if self.tfidf_vectorizer is None:
            self.tfidf_vectorizer = TfidfVectorizer(
                max_features=8000,
                ngram_range=(1, 3),  # Include trigrams
                stop_words='english',
                min_df=2,
                max_df=0.95,
                sublinear_tf=True  # Use sublinear TF scaling
            )
            tfidf_features = self.tfidf_vectorizer.fit_transform(texts).toarray()
        else:
            tfidf_features = self.tfidf_vectorizer.transform(texts).toarray()
        
        # Advanced text features
        text_features = self.extract_advanced_features(texts)
        
        # Combine all features
        combined_features = np.hstack([
            glove_features,
            tfidf_features,
            text_features
        ])
        
        print(f"📊 Combined feature shape: {combined_features.shape}")
        return combined_features
    
    def create_advanced_ensemble(self):
        """Create advanced ensemble with stacking"""
        print("🏗️ Creating advanced ensemble model...")
        
        # Base models
        base_models = [
            ('rf', RandomForestClassifier(
                n_estimators=300,
                max_depth=20,
                min_samples_split=3,
                min_samples_leaf=1,
                random_state=42,
                n_jobs=-1
            )),
            ('gb', GradientBoostingClassifier(
                n_estimators=300,
                learning_rate=0.05,
                max_depth=7,
                random_state=42
            )),
            ('lr', LogisticRegression(
                C=0.1,
                penalty='l1',
                solver='liblinear',
                random_state=42,
                max_iter=2000
            )),
            ('svm', SVC(
                C=100,
                kernel='rbf',
                gamma=0.001,
                random_state=42,
                probability=True
            )),
            ('mlp', MLPClassifier(
                hidden_layer_sizes=(200, 100),
                activation='relu',
                solver='adam',
                alpha=0.01,
                random_state=42,
                max_iter=500
            ))
        ]
        
        # Meta-learner
        meta_learner = LogisticRegression(random_state=42, max_iter=1000)
        
        # Create stacking classifier
        stacking_classifier = StackingClassifier(
            estimators=base_models,
            final_estimator=meta_learner,
            cv=5,
            stack_method='predict_proba'
        )
        
        return stacking_classifier
    
    def train_advanced_ensemble(self, X, y):
        """Train advanced ensemble model"""
        print("🚀 Training advanced ensemble model...")
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )
        
        # Prepare features
        X_train_features = self.prepare_advanced_features(X_train)
        X_test_features = self.prepare_advanced_features(X_test)
        
        # Scale features
        X_train_scaled = self.scaler.fit_transform(X_train_features)
        X_test_scaled = self.scaler.transform(X_test_features)
        
        # Create and train ensemble
        self.ensemble_model = self.create_advanced_ensemble()
        
        print("🌲 Training advanced ensemble...")
        self.ensemble_model.fit(X_train_scaled, y_train)
        
        # Evaluate
        y_pred = self.ensemble_model.predict(X_test_scaled)
        accuracy = accuracy_score(y_test, y_pred)
        
        # Cross-validation
        cv_scores = cross_val_score(self.ensemble_model, X_train_scaled, y_train, cv=5)
        
        print(f"🎯 Advanced Ensemble Test Accuracy: {accuracy:.4f}")
        print(f"🎯 Advanced Ensemble CV Accuracy: {cv_scores.mean():.4f} (+/- {cv_scores.std() * 2:.4f})")
        
        self.best_accuracy = accuracy
        return accuracy
    
    def save_advanced_ensemble(self, model_name="AdvancedEnsembleModel"):
        """Save the advanced ensemble model"""
        if self.ensemble_model is not None:
            joblib.dump(self.ensemble_model, f"{model_name}_ensemble.joblib")
            joblib.dump(self.scaler, f"{model_name}_scaler.joblib")
            joblib.dump(self.tfidf_vectorizer, f"{model_name}_tfidf.joblib")
            joblib.dump(self.glove_embeddings, f"{model_name}_glove.joblib")
            
            print(f"\n✅ Advanced ensemble model saved: {model_name}_ensemble.joblib")
            print(f"✅ Scaler saved: {model_name}_scaler.joblib")
            print(f"✅ TF-IDF vectorizer saved: {model_name}_tfidf.joblib")
            print(f"✅ GloVe embeddings saved: {model_name}_glove.joblib")
            return True
        return False

def main():
    print("🎯 Advanced Ensemble Sentiment Analysis")
    print("=" * 50)
    
    model = AdvancedEnsembleModel()
    
    # Load GloVe embeddings
    model.load_glove_embeddings()
    
    # Load data
    X, y = model.load_emotion_dataset()
    
    # Train advanced ensemble
    accuracy = model.train_advanced_ensemble(X, y)
    
    # Save model
    model.save_advanced_ensemble()
    
    print(f"\n🎯 Advanced ensemble training completed!")
    print(f"🏆 Best accuracy achieved: {model.best_accuracy:.4f}")
    
    if model.best_accuracy >= 0.85:
        print("🎉 Congratulations! You've reached 85%+ accuracy!")
    else:
        print("💡 Consider trying BERT fine-tuning for even higher accuracy")

if __name__ == "__main__":
    main()
