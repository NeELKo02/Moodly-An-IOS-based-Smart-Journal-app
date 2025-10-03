# Custom CoreML Model Training with Kaggle Datasets

## 🎯 Overview
This guide shows how to train a custom sentiment analysis model using Kaggle datasets and integrate it into your SmartJournal app.

## 📊 Recommended Kaggle Datasets

### 1. **Sentiment140** (Most Popular)
- **Size**: 1.6M tweets
- **Labels**: Positive (4), Negative (0)
- **Best for**: General sentiment analysis
- **URL**: https://www.kaggle.com/datasets/kazanova/sentiment140

### 2. **Emotion Dataset for Emotion Recognition**
- **Size**: 20K+ texts
- **Labels**: 6 emotions (joy, sadness, anger, fear, love, surprise)
- **Best for**: Emotional journaling analysis
- **URL**: https://www.kaggle.com/datasets/praveengovi/emotions-dataset-for-nlp

### 3. **Mental Health Sentiment Analysis**
- **Size**: 5K+ Reddit posts
- **Labels**: Mental health sentiment
- **Best for**: Wellness-focused journaling
- **URL**: https://www.kaggle.com/datasets/bhavikbb/persuade-categorize-mental-health

### 4. **Daily Dialog Dataset**
- **Size**: 13K+ conversations
- **Labels**: Multi-emotion classification
- **Best for**: Conversational journaling
- **URL**: https://www.kaggle.com/datasets/parthplc/daily-dialog-dataset

## 🛠 Implementation Steps

### Step 1: Data Preprocessing Script

```python
# train_sentiment_model.py
import pandas as pd
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Embedding, LSTM, Dense, Dropout
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
import coremltools as ct

class SentimentModelTrainer:
    def __init__(self, dataset_path):
        self.dataset_path = dataset_path
        self.tokenizer = Tokenizer(num_words=10000, oov_token='<OOV>')
        self.label_encoder = LabelEncoder()
        
    def load_and_preprocess_data(self):
        """Load and preprocess the Kaggle dataset"""
        # Load dataset (adjust based on your chosen dataset)
        df = pd.read_csv(self.dataset_path)
        
        # Clean text data
        df['text'] = df['text'].str.lower()
        df['text'] = df['text'].str.replace('[^a-zA-Z\s]', '', regex=True)
        
        # Prepare features and labels
        texts = df['text'].values
        labels = df['sentiment'].values  # Adjust column name as needed
        
        return texts, labels
    
    def prepare_training_data(self, texts, labels):
        """Tokenize and pad sequences"""
        # Fit tokenizer on texts
        self.tokenizer.fit_on_texts(texts)
        
        # Convert texts to sequences
        sequences = self.tokenizer.texts_to_sequences(texts)
        
        # Pad sequences to same length
        max_length = 100  # Adjust based on your data
        padded_sequences = pad_sequences(sequences, maxlen=max_length, padding='post')
        
        # Encode labels
        encoded_labels = self.label_encoder.fit_transform(labels)
        
        return padded_sequences, encoded_labels
    
    def build_model(self, vocab_size, max_length, num_classes):
        """Build LSTM model for sentiment analysis"""
        model = Sequential([
            Embedding(vocab_size, 128, input_length=max_length),
            LSTM(64, return_sequences=True),
            Dropout(0.3),
            LSTM(32),
            Dropout(0.3),
            Dense(64, activation='relu'),
            Dropout(0.3),
            Dense(num_classes, activation='softmax')
        ])
        
        model.compile(
            optimizer='adam',
            loss='sparse_categorical_crossentropy',
            metrics=['accuracy']
        )
        
        return model
    
    def train_model(self, X, y, epochs=10, batch_size=32):
        """Train the sentiment analysis model"""
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )
        
        # Build model
        vocab_size = len(self.tokenizer.word_index) + 1
        max_length = X.shape[1]
        num_classes = len(np.unique(y))
        
        model = self.build_model(vocab_size, max_length, num_classes)
        
        # Train model
        history = model.fit(
            X_train, y_train,
            epochs=epochs,
            batch_size=batch_size,
            validation_data=(X_test, y_test),
            verbose=1
        )
        
        return model, history
    
    def convert_to_coreml(self, model, model_name="SentimentClassifier"):
        """Convert TensorFlow model to CoreML format"""
        # Convert to CoreML
        coreml_model = ct.convert(
            model,
            inputs=[ct.TensorType(name="text", shape=(1, 100))],  # Adjust shape as needed
            outputs=[ct.TensorType(name="sentiment", shape=(1, 2))]  # Adjust for your classes
        )
        
        # Add metadata
        coreml_model.short_description = "Custom sentiment analysis model for SmartJournal"
        coreml_model.author = "SmartJournal Team"
        coreml_model.license = "MIT"
        
        # Save model
        coreml_model.save(f"{model_name}.mlmodel")
        print(f"CoreML model saved as {model_name}.mlmodel")
        
        return coreml_model

# Usage example
if __name__ == "__main__":
    trainer = SentimentModelTrainer("sentiment140.csv")
    
    # Load and preprocess data
    texts, labels = trainer.load_and_preprocess_data()
    X, y = trainer.prepare_training_data(texts, labels)
    
    # Train model
    model, history = trainer.train_model(X, y, epochs=5)
    
    # Convert to CoreML
    coreml_model = trainer.convert_to_coreml(model)
    
    print("Training completed! Model ready for iOS integration.")
```

### Step 2: Enhanced NLPAnalyzer with Custom Model

```swift
// CustomNLPAnalyzer.swift
import Foundation
import NaturalLanguage
import CoreML

@MainActor
class CustomNLPAnalyzer: ObservableObject {
    private let customModel: MLModel?
    private let tokenizer: NLTokenizer
    private let languageRecognizer: NLLanguageRecognizer
    
    init() {
        // Load custom CoreML model
        if let modelURL = Bundle.main.url(forResource: "SentimentClassifier", withExtension: "mlmodelc") {
            do {
                self.customModel = try MLModel(contentsOf: modelURL)
            } catch {
                print("Failed to load custom model: \(error)")
                self.customModel = nil
            }
        } else {
            self.customModel = nil
        }
        
        self.tokenizer = NLTokenizer(unit: .word)
        self.languageRecognizer = NLLanguageRecognizer()
    }
    
    func analyzeSentimentWithCustomModel(_ text: String) async -> Double {
        guard let model = customModel else {
            // Fallback to Apple's built-in sentiment analysis
            return await analyzeSentimentWithApple(text)
        }
        
        do {
            // Preprocess text for custom model
            let preprocessedText = preprocessTextForModel(text)
            
            // Create input for CoreML model
            let input = try MLDictionaryFeatureProvider(dictionary: [
                "text": MLMultiArray(Array(repeating: 0.0, count: 100)) // Adjust based on your model
            ])
            
            // Make prediction
            let prediction = try model.prediction(from: input)
            
            // Extract sentiment score
            if let sentimentArray = prediction.featureValue(for: "sentiment")?.multiArrayValue {
                // Convert model output to sentiment score (-1.0 to 1.0)
                let positiveScore = sentimentArray[1].doubleValue
                let negativeScore = sentimentArray[0].doubleValue
                
                // Convert to -1.0 to 1.0 scale
                return (positiveScore - negativeScore) / (positiveScore + negativeScore)
            }
            
        } catch {
            print("Custom model prediction failed: \(error)")
        }
        
        // Fallback to Apple's sentiment analysis
        return await analyzeSentimentWithApple(text)
    }
    
    private func preprocessTextForModel(_ text: String) -> String {
        // Implement the same preprocessing as used during training
        return text.lowercased()
            .replacingOccurrences(of: "[^a-zA-Z\\s]", with: "", options: .regularExpression)
    }
    
    private func analyzeSentimentWithApple(_ text: String) async -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        var totalSentiment: Double = 0
        var count = 0
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .sentence, scheme: .sentimentScore) { tag, tokenRange in
            if let sentiment = tag?.rawValue, let score = Double(sentiment) {
                totalSentiment += score
                count += 1
            }
            return true
        }
        
        return count > 0 ? totalSentiment / Double(count) : 0.0
    }
}
```

### Step 3: Integration with SmartJournal

```swift
// Update ContentView.swift to use custom model
@StateObject private var customNLPAnalyzer = CustomNLPAnalyzer()

private func performFullAnalysis() async {
    isAnalyzing = true
    
    // Use custom model for sentiment analysis
    sentimentScore = await customNLPAnalyzer.analyzeSentimentWithCustomModel(text)
    
    // Rest of your existing analysis...
    keywords = await nlpAnalyzer.extractKeywords(text)
    triggers = await nlpAnalyzer.detectTriggers(text)
    summary = await nlpAnalyzer.generateSummary(text, sentiment: sentimentScore ?? 0.0, triggers: triggers)
    
    isAnalyzing = false
}
```

## 📋 Requirements

### Python Environment
```bash
pip install pandas numpy tensorflow scikit-learn coremltools
```

### iOS Requirements
- Xcode 15+
- iOS 17+
- CoreML framework

## 🚀 Quick Start

1. **Download a Kaggle dataset** (e.g., Sentiment140)
2. **Run the training script** to generate your custom model
3. **Add the .mlmodel file** to your Xcode project
4. **Update your NLPAnalyzer** to use the custom model
5. **Test and iterate** based on your specific journaling data

## 🎯 Benefits of Custom Model

- **Domain-specific accuracy** for journaling text
- **Custom emotion categories** (not just positive/negative)
- **Better performance** on personal writing styles
- **Privacy-first** - all processing on-device
- **Continuous improvement** - can retrain with your own data

## 📊 Model Performance Tips

1. **Start with Sentiment140** for general sentiment
2. **Fine-tune with journaling-specific data** if available
3. **Use data augmentation** to increase training data
4. **Experiment with different architectures** (LSTM, Transformer, etc.)
5. **Validate on held-out test data** before deployment

This approach will give you a much more tailored sentiment analysis model for your SmartJournal app! 🎉
