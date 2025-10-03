import pandas as pd
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Embedding, LSTM, Dense, Dropout
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report, confusion_matrix
import coremltools as ct
import os
import re
import json
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import cross_val_score
import joblib

class EmotionModelTrainer:
    def __init__(self):
        self.tokenizer = Tokenizer(num_words=15000, oov_token='<OOV>')  # Increased vocab
        self.label_encoder = LabelEncoder()
        self.model = None
        self.vocab_size = 15000
        self.max_length = 150  # Increased sequence length
        self.tfidf_vectorizer = None
        self.random_forest_model = None

    def preprocess_text(self, text):
        """Clean and preprocess text"""
        if pd.isna(text):
            return ""
        
        # Convert to string and lowercase
        text = str(text).lower()
        
        # Remove URLs
        text = re.sub(r'http\S+|www\S+|https\S+', '', text, flags=re.MULTILINE)
        
        # Remove user mentions and hashtags
        text = re.sub(r'@\w+|#\w+', '', text)
        
        # Remove extra whitespace
        text = re.sub(r'\s+', ' ', text)
        
        # Remove special characters but keep basic punctuation
        text = re.sub(r'[^a-zA-Z0-9\s.,!?]', '', text)
        
        return text.strip()

    def load_emotion_dataset(self, file_path):
        """Load emotion dataset"""
        print(f"📊 Loading emotion dataset from {file_path}")
        
        df = pd.read_csv(file_path)
        print(f"✅ Loaded {len(df)} samples")
        print(f"📋 Columns: {list(df.columns)}")
        
        # Map emotions to sentiment scores
        emotion_to_sentiment = {
            'happy': 'positive',
            'love': 'positive', 
            'surprise': 'neutral',
            'anger': 'negative',
            'sadness': 'negative',
            'fear': 'negative'
        }
        
        df['sentiment'] = df['Emotion'].map(emotion_to_sentiment)
        
        # Clean and filter data
        df = df.dropna(subset=['Text', 'sentiment'])
        df = df[df['sentiment'].notna()]
        
        print(f"📊 Emotion distribution:")
        print(df['Emotion'].value_counts())
        print(f"📊 Sentiment distribution:")
        print(df['sentiment'].value_counts())
        
        return df

    def prepare_training_data(self, df, max_samples=15000):  # Use more samples for better training
        """Prepare data for training"""
        print("🔄 Preparing training data...")
        
        # Limit samples if dataset is too large
        if len(df) > max_samples:
            df = df.sample(n=max_samples, random_state=42)
            print(f"📊 Limited to {max_samples} samples")
        
        # Clean text
        df['text'] = df['Text'].apply(self.preprocess_text)
        
        # Remove empty texts
        df = df[df['text'].str.len() > 10]
        
        # Prepare features and labels
        texts = df['text'].values
        labels = df['sentiment'].values
        
        print(f"📊 Final dataset: {len(texts)} samples")
        print(f"📊 Label distribution: {np.unique(labels, return_counts=True)}")
        
        return texts, labels

    def create_lstm_model(self, num_classes):
        """Create LSTM model"""
        print("🏗️ Creating LSTM model...")
        
        # Optimized model architecture
        model = Sequential([
            Embedding(self.vocab_size, 256, input_length=self.max_length),  # Increased embedding dim
            LSTM(128, return_sequences=True, dropout=0.3, recurrent_dropout=0.3),  # Deeper LSTM
            LSTM(64, dropout=0.3, recurrent_dropout=0.3),  # Second LSTM layer
            Dense(64, activation='relu', kernel_regularizer=tf.keras.regularizers.l2(0.01)),  # L2 regularization
            Dropout(0.4),  # Increased dropout
            Dense(32, activation='relu', kernel_regularizer=tf.keras.regularizers.l2(0.01)),
            Dropout(0.4),
            Dense(num_classes, activation='softmax')
        ])
        
        # Optimized training configuration
        model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=0.0005, beta_1=0.9, beta_2=0.999),  # Adam with custom LR
            loss='sparse_categorical_crossentropy',
            metrics=['accuracy']
        )
        
        return model

    def create_random_forest_model(self, X_train, y_train):
        """Create Random Forest model with TF-IDF"""
        print("🌲 Creating Random Forest model...")
        
        # TF-IDF vectorization
        self.tfidf_vectorizer = TfidfVectorizer(
            max_features=10000,
            ngram_range=(1, 2),  # Unigrams and bigrams
            stop_words='english',
            min_df=2,
            max_df=0.95
        )
        
        X_train_tfidf = self.tfidf_vectorizer.fit_transform(X_train)
        
        # Random Forest with optimized parameters
        self.random_forest_model = RandomForestClassifier(
            n_estimators=200,
            max_depth=20,
            min_samples_split=5,
            min_samples_leaf=2,
            random_state=42,
            n_jobs=-1
        )
        
        print("🌲 Training Random Forest...")
        self.random_forest_model.fit(X_train_tfidf, y_train)
        
        return self.random_forest_model

    def train_lstm_model(self, X, y, epochs=25, batch_size=64, validation_split=0.2):  # Optimized parameters
        """Train LSTM model"""
        print("🚀 Training LSTM model...")
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=validation_split, random_state=42, stratify=y
        )
        
        # Tokenize and pad sequences
        self.tokenizer.fit_on_texts(X_train)
        X_train_seq = self.tokenizer.texts_to_sequences(X_train)
        X_test_seq = self.tokenizer.texts_to_sequences(X_test)
        
        X_train_padded = pad_sequences(X_train_seq, maxlen=self.max_length, padding='post')
        X_test_padded = pad_sequences(X_test_seq, maxlen=self.max_length, padding='post')
        
        # Encode labels
        y_train_encoded = self.label_encoder.fit_transform(y_train)
        y_test_encoded = self.label_encoder.transform(y_test)
        
        # Create model
        num_classes = len(self.label_encoder.classes_)
        self.model = self.create_lstm_model(num_classes)
        
        # Add callbacks for better training
        callbacks = [
            tf.keras.callbacks.EarlyStopping(
                monitor='val_accuracy',
                patience=5,
                restore_best_weights=True,
                verbose=1
            ),
            tf.keras.callbacks.ReduceLROnPlateau(
                monitor='val_loss',
                factor=0.5,
                patience=3,
                min_lr=1e-6,
                verbose=1
            )
        ]
        
        # Train model with optimized parameters
        history = self.model.fit(
            X_train_padded, y_train_encoded,
            epochs=epochs,
            batch_size=batch_size,
            validation_data=(X_test_padded, y_test_encoded),
            callbacks=callbacks,
            verbose=1
        )
        
        # Evaluate
        test_loss, test_accuracy = self.model.evaluate(X_test_padded, y_test_encoded, verbose=0)
        print(f"🎯 LSTM Test Accuracy: {test_accuracy:.4f}")
        
        return history

    def train_random_forest_model(self, X, y, validation_split=0.2):
        """Train Random Forest model"""
        print("🌲 Training Random Forest model...")
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=validation_split, random_state=42, stratify=y
        )
        
        # Train model
        self.create_random_forest_model(X_train, y_train)
        
        # Evaluate
        X_test_tfidf = self.tfidf_vectorizer.transform(X_test)
        y_pred = self.random_forest_model.predict(X_test_tfidf)
        
        accuracy = accuracy_score(y_test, y_pred)
        print(f"🎯 Random Forest Test Accuracy: {accuracy:.4f}")
        
        # Cross-validation
        X_train_tfidf = self.tfidf_vectorizer.transform(X_train)
        cv_scores = cross_val_score(self.random_forest_model, X_train_tfidf, y_train, cv=5)
        print(f"🎯 Random Forest CV Accuracy: {cv_scores.mean():.4f} (+/- {cv_scores.std() * 2:.4f})")
        
        return accuracy

    def convert_to_coreml(self, model_name="EmotionSentimentModel"):
        """Convert model to CoreML format"""
        print("🔄 Converting to CoreML...")
        
        if self.model is not None:
            # LSTM model conversion
            try:
                coreml_model = ct.convert(
                    self.model,
                    source="tensorflow",
                    convert_to="mlprogram"
                )
                
                # Set input/output descriptions
                coreml_model.input_description["text"] = "Input text for emotion analysis"
                coreml_model.output_description["sentiment"] = "Predicted sentiment (positive/negative/neutral)"
                
                # Save model
                model_path = f"{model_name}.mlpackage"
                coreml_model.save(model_path)
                print(f"✅ CoreML model saved: {model_path}")
                
                # Save tokenizer config
                tokenizer_config = {
                    "vocab_size": self.vocab_size,
                    "max_length": self.max_length,
                    "word_index": self.tokenizer.word_index
                }
                
                with open("tokenizer_config.json", "w") as f:
                    json.dump(tokenizer_config, f, indent=2)
                print("✅ Tokenizer config saved: tokenizer_config.json")
                
            except Exception as e:
                print(f"❌ CoreML conversion failed: {e}")
                return False
        else:
            print("❌ No model to convert")
            return False
        
        return True

    def save_random_forest_model(self, model_name="EmotionSentimentModel"):
        """Save Random Forest model and vectorizer"""
        if self.random_forest_model is not None and self.tfidf_vectorizer is not None:
            # Save model
            joblib.dump(self.random_forest_model, f"{model_name}_rf.joblib")
            joblib.dump(self.tfidf_vectorizer, f"{model_name}_tfidf.joblib")
            print(f"✅ Random Forest model saved: {model_name}_rf.joblib")
            print(f"✅ TF-IDF vectorizer saved: {model_name}_tfidf.joblib")
            return True
        else:
            print("❌ No Random Forest model to save")
            return False

def main():
    print("🤖 Emotion Sentiment Model Trainer")
    print("=" * 50)
    
    trainer = EmotionModelTrainer()
    
    print("\n📋 Available datasets:")
    print("1. Sample data (20 samples)")
    print("2. Emotion dataset (21,460 samples)")
    print("3. Load sample_data.csv")
    print("4. Random Forest + TF-IDF (Recommended for better accuracy)")
    
    choice = input("\nSelect dataset (1-4): ").strip()
    
    if choice == "1":
        # Sample data
        sample_data = {
            'text': [
                "I love this app! It's amazing!",
                "This is terrible, I hate it.",
                "It's okay, nothing special.",
                "Fantastic! Best app ever!",
                "I'm so disappointed with this.",
                "Great experience, highly recommend!",
                "Worst app I've ever used.",
                "Pretty good, I like it.",
                "Absolutely wonderful!",
                "Not impressed at all.",
                "Excellent quality!",
                "This is awful.",
                "Decent app, could be better.",
                "Outstanding performance!",
                "I'm frustrated with this.",
                "Love it! Five stars!",
                "This is garbage.",
                "It's fine, nothing more.",
                "Incredible! So happy!",
                "I'm not satisfied."
            ],
            'sentiment': [
                'positive', 'negative', 'neutral', 'positive', 'negative',
                'positive', 'negative', 'neutral', 'positive', 'negative',
                'positive', 'negative', 'neutral', 'positive', 'negative',
                'positive', 'negative', 'neutral', 'positive', 'negative'
            ]
        }
        
        df = pd.DataFrame(sample_data)
        print(f"📊 Using sample data: {len(df)} samples")
        
    elif choice == "2":
        # Emotion dataset
        dataset_path = "Emotion_final.csv"
        if not os.path.exists(dataset_path):
            print("❌ Emotion_final.csv not found!")
            return
        
        df = trainer.load_emotion_dataset(dataset_path)
        
    elif choice == "3":
        # Load sample_data.csv
        if not os.path.exists("sample_data.csv"):
            print("❌ sample_data.csv not found!")
            return
        
        df = pd.read_csv("sample_data.csv")
        print(f"📊 Loaded sample data: {len(df)} samples")
        
    elif choice == "4":
        # Random Forest approach
        dataset_path = "Emotion_final.csv"
        if not os.path.exists(dataset_path):
            print("❌ Emotion_final.csv not found!")
            return
        
        df = trainer.load_emotion_dataset(dataset_path)
        
        # Prepare data
        texts, labels = trainer.prepare_training_data(df)
        
        # Train Random Forest
        accuracy = trainer.train_random_forest_model(texts, labels)
        
        # Save model
        trainer.save_random_forest_model()
        
        print(f"\n🎯 Final Random Forest Accuracy: {accuracy:.4f}")
        print("✅ Random Forest model training completed!")
        return
        
    else:
        print("❌ Invalid choice!")
        return
    
    # Prepare data
    texts, labels = trainer.prepare_training_data(df)
    
    # Train LSTM model
    history = trainer.train_lstm_model(texts, labels)
    
    # Convert to CoreML
    if trainer.convert_to_coreml():
        print("\n🎯 Model training completed successfully!")
        print("📱 CoreML model ready for iOS integration!")
    else:
        print("\n❌ Model training failed!")

if __name__ == "__main__":
    main()