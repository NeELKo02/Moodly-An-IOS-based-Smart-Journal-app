import pandas as pd
import numpy as np
import re
import os
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier, VotingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import StandardScaler
from sklearn.feature_extraction.text import TfidfVectorizer
import joblib
from tqdm import tqdm
import warnings
warnings.filterwarnings('ignore')

class Fast85AccuracyModel:
    def __init__(self):
        self.glove_embeddings = {}
        self.embedding_dim = 100
        self.ensemble_model = None
        self.scaler = StandardScaler()
        self.tfidf_vectorizer = None
        self.best_accuracy = 0
        
    def load_glove_embeddings(self):
        """Load GloVe embeddings quickly
        NOTE: GloVe files are not included in the repository due to size (2.97GB).
        Download from: https://nlp.stanford.edu/projects/glove/
        Place glove.6B.100d.txt in the project root before running this script.
        """
        print("🔄 Loading GloVe embeddings...")
        
        glove_file = "glove.6B.100d.txt"
        
        with open(glove_file, 'r', encoding='utf-8') as f:
            for line in tqdm(f, desc="Loading", total=400000):
                values = line.split()
                word = values[0]
                vector = np.array(values[1:], dtype='float32')
                self.glove_embeddings[word] = vector
                
                # Load only 30k most common words for speed
                if len(self.glove_embeddings) >= 30000:
                    break
        
        print(f"✅ Loaded {len(self.glove_embeddings)} word embeddings!")
        return self.glove_embeddings
    
    def smart_preprocess_text(self, text):
        """Smart text preprocessing for better accuracy"""
        if pd.isna(text):
            return ""
        
        text = str(text).lower()
        
        # Keep important punctuation for sentiment
        text = re.sub(r'[^a-zA-Z\s.,!?]', '', text)
        text = re.sub(r'\s+', ' ', text).strip()
        
        return text
    
    def text_to_glove_vector(self, text, max_length=40):  # Reduced for speed
        """Fast GloVe vectorization"""
        words = text.split()[:max_length]
        
        embedding_vector = np.zeros(self.embedding_dim)
        word_count = 0
        
        for word in words:
            if word in self.glove_embeddings:
                embedding_vector += self.glove_embeddings[word]
                word_count += 1
        
        if word_count > 0:
            embedding_vector /= word_count
        
        return embedding_vector
    
    def extract_smart_features(self, texts):
        """Extract smart features for better accuracy"""
        features = []
        
        for text in texts:
            # Basic features
            text_length = len(text)
            word_count = len(text.split())
            
            # Sentiment indicators
            exclamation_count = text.count('!')
            question_count = text.count('?')
            
            # Emotional words (domain-specific)
            positive_words = ['good', 'great', 'excellent', 'amazing', 'wonderful', 'fantastic', 'love', 'happy', 'joy', 'smile', 'beautiful', 'perfect', 'awesome', 'brilliant']
            negative_words = ['bad', 'terrible', 'awful', 'horrible', 'hate', 'sad', 'angry', 'frustrated', 'disappointed', 'worst', 'hate', 'disgusting', 'annoying']
            
            words = text.split()
            positive_count = sum(1 for word in words if word.lower() in positive_words)
            negative_count = sum(1 for word in words if word.lower() in negative_words)
            
            # Punctuation patterns
            multiple_exclamation = text.count('!!')
            multiple_question = text.count('??')
            
            # Word length patterns
            avg_word_length = np.mean([len(word) for word in words]) if words else 0
            
            text_features = [
                text_length,
                word_count,
                exclamation_count,
                question_count,
                positive_count,
                negative_count,
                multiple_exclamation,
                multiple_question,
                avg_word_length
            ]
            features.append(text_features)
        
        return np.array(features)
    
    def load_emotion_dataset(self):
        """Load emotion dataset with smart sampling"""
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
        df['text'] = df['Text'].apply(self.smart_preprocess_text)
        df = df[df['text'].str.len() > 10]
        
        # Use 6000 samples for speed but good accuracy
        if len(df) > 6000:
            df = df.sample(n=6000, random_state=42)
        
        print(f"📊 Final dataset: {len(df)} samples")
        print(f"📊 Sentiment distribution:")
        print(df['sentiment'].value_counts())
        
        return df['text'].values, df['sentiment'].values
    
    def prepare_smart_features(self, texts):
        """Prepare smart features for better accuracy"""
        print("🔄 Preparing smart features...")
        
        # GloVe embeddings
        glove_features = []
        for text in tqdm(texts, desc="GloVe processing"):
            glove_vector = self.text_to_glove_vector(text)
            glove_features.append(glove_vector)
        glove_features = np.array(glove_features)
        
        # TF-IDF with optimized settings
        if self.tfidf_vectorizer is None:
            self.tfidf_vectorizer = TfidfVectorizer(
                max_features=3000,  # Reduced for speed
                ngram_range=(1, 2),
                stop_words='english',
                min_df=2,
                max_df=0.95,
                sublinear_tf=True
            )
            tfidf_features = self.tfidf_vectorizer.fit_transform(texts).toarray()
        else:
            tfidf_features = self.tfidf_vectorizer.transform(texts).toarray()
        
        # Smart text features
        text_features = self.extract_smart_features(texts)
        
        # Combine features
        combined_features = np.hstack([
            glove_features,
            tfidf_features,
            text_features
        ])
        
        print(f"📊 Combined feature shape: {combined_features.shape}")
        return combined_features
    
    def create_optimized_ensemble(self):
        """Create optimized ensemble for 85% accuracy"""
        print("🏗️ Creating optimized ensemble...")
        
        # Optimized base models
        rf = RandomForestClassifier(
            n_estimators=200,
            max_depth=15,
            min_samples_split=3,
            min_samples_leaf=1,
            random_state=42,
            n_jobs=-1
        )
        
        gb = GradientBoostingClassifier(
            n_estimators=200,
            learning_rate=0.1,
            max_depth=6,
            random_state=42
        )
        
        lr = LogisticRegression(
            C=0.1,
            penalty='l1',
            solver='liblinear',
            random_state=42,
            max_iter=1000
        )
        
        svm = SVC(
            C=10,
            kernel='rbf',
            gamma=0.001,
            random_state=42,
            probability=True
        )
        
        # Create voting classifier
        ensemble = VotingClassifier(
            estimators=[
                ('rf', rf),
                ('gb', gb),
                ('lr', lr),
                ('svm', svm)
            ],
            voting='soft'
        )
        
        return ensemble
    
    def train_optimized_ensemble(self, X, y):
        """Train optimized ensemble for 85% accuracy"""
        print("🚀 Training optimized ensemble...")
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )
        
        # Prepare features
        X_train_features = self.prepare_smart_features(X_train)
        X_test_features = self.prepare_smart_features(X_test)
        
        # Scale features
        X_train_scaled = self.scaler.fit_transform(X_train_features)
        X_test_scaled = self.scaler.transform(X_test_features)
        
        # Create and train ensemble
        self.ensemble_model = self.create_optimized_ensemble()
        
        print("🌲 Training optimized ensemble...")
        self.ensemble_model.fit(X_train_scaled, y_train)
        
        # Evaluate
        y_pred = self.ensemble_model.predict(X_test_scaled)
        accuracy = accuracy_score(y_test, y_pred)
        
        # Cross-validation
        cv_scores = cross_val_score(self.ensemble_model, X_train_scaled, y_train, cv=3)  # Reduced CV for speed
        
        print(f"🎯 Optimized Ensemble Test Accuracy: {accuracy:.4f}")
        print(f"🎯 Optimized Ensemble CV Accuracy: {cv_scores.mean():.4f} (+/- {cv_scores.std() * 2:.4f})")
        
        self.best_accuracy = accuracy
        return accuracy
    
    def save_optimized_model(self, model_name="Fast85AccuracyModel"):
        """Save the optimized model"""
        if self.ensemble_model is not None:
            joblib.dump(self.ensemble_model, f"{model_name}_ensemble.joblib")
            joblib.dump(self.scaler, f"{model_name}_scaler.joblib")
            joblib.dump(self.tfidf_vectorizer, f"{model_name}_tfidf.joblib")
            joblib.dump(self.glove_embeddings, f"{model_name}_glove.joblib")
            
            print(f"\n✅ Optimized model saved: {model_name}_ensemble.joblib")
            print(f"✅ Scaler saved: {model_name}_scaler.joblib")
            print(f"✅ TF-IDF vectorizer saved: {model_name}_tfidf.joblib")
            print(f"✅ GloVe embeddings saved: {model_name}_glove.joblib")
            return True
        return False

def main():
    print("🚀 Fast 85% Accuracy Model")
    print("=" * 40)
    
    model = Fast85AccuracyModel()
    
    # Load GloVe embeddings
    model.load_glove_embeddings()
    
    # Load data
    X, y = model.load_emotion_dataset()
    
    # Train optimized ensemble
    accuracy = model.train_optimized_ensemble(X, y)
    
    # Save model
    model.save_optimized_model()
    
    print(f"\n🎯 Optimized training completed!")
    print(f"🏆 Best accuracy achieved: {model.best_accuracy:.4f}")
    
    if model.best_accuracy >= 0.85:
        print("🎉 Congratulations! You've reached 85%+ accuracy!")
    elif model.best_accuracy >= 0.80:
        print("🎯 Great! You've reached 80%+ accuracy!")
        print("💡 For 85%+, consider BERT fine-tuning")
    else:
        print("💡 Consider trying BERT fine-tuning for 85%+ accuracy")

if __name__ == "__main__":
    main()
