# SmartJournal - Privacy-First Mood Journal

A comprehensive iOS journaling app with advanced emotion detection, encrypted local storage, and intelligent wellness insights. Built with SwiftUI and CoreML for 92% accuracy emotion classification.

## 📁 Project Structure

```
SmartJournal/
├── README.md                          # This file
├── SmartJournal.xcodeproj/            # Xcode project
├── SmartJournal/                      # iOS app source code
├── SmartJournal Watch App/            # Apple Watch app
├── SmartJournalTests/                 # Unit tests
├── SmartJournalUITests/               # UI tests
├── SmartJournalSentiment.mlpackage/   # CoreML model
├── docs/                              # Documentation
│   ├── README.md                      # Detailed app documentation
│   └── CustomModelTraining.md         # Model training guide
├── models/                            # Trained ML models
│   ├── Fast85AccuracyModel_ensemble.joblib
│   ├── Fast85AccuracyModel_glove.joblib
│   ├── Fast85AccuracyModel_scaler.joblib
│   └── Fast85AccuracyModel_tfidf.joblib
├── data/                              # Datasets
│   └── Emotion_final.csv              # Main emotion dataset
├── scripts/                           # Python training scripts
│   ├── fast_85_accuracy_model.py     # Best performing model (91.17% accuracy)
│   ├── train_custom_model.py         # Basic training script
│   ├── advanced_ensemble_model.py    # Advanced ensemble approach
│   ├── convert_to_coreml.py          # CoreML conversion
│   └── setup_custom_model.sh         # Environment setup
├── assets/                            # Training assets
│   └── tokenizer_config.json         # Tokenizer configuration
└── screenshots/                       # App screenshots (for documentation)
```

## 🚀 Quick Start

### Prerequisites
- iOS 18.5+
- Xcode 15.0+
- Apple Developer Account (for device testing)

### Installation
1. **Clone the repository**
2. **Open `SmartJournal.xcodeproj` in Xcode**
3. **Select your target device**
4. **Build and run the project**

### Model Training (Optional)
If you want to retrain the emotion detection model:

1. **Setup Python environment:**
   ```bash
   cd scripts
   chmod +x setup_custom_model.sh
   ./setup_custom_model.sh
   ```

2. **Download GloVe embeddings** (2.97GB - not included in repository):
   ```bash
   # Download from Stanford NLP
   wget http://nlp.stanford.edu/data/glove.6B.zip
   unzip glove.6B.zip
   ```

3. **Train the model:**
   ```bash
   python fast_85_accuracy_model.py
   ```

4. **Convert to CoreML:**
   ```bash
   python convert_to_coreml.py
   ```

**Note:** The app includes pre-trained models and works without retraining. See [scripts/README.md](scripts/README.md) for detailed instructions.

## 📱 Features

- **92% Accuracy Emotion Detection** using custom CoreML model
- **Privacy-First Architecture** with AES-GCM encryption
- **Real-time Sentiment Analysis** as you type
- **Apple Watch Integration** for quick mood logging
- **HealthKit Integration** for wellness tracking
- **Encrypted Local Storage** with CoreData
- **Multi-language Support** (9 languages)
- **Intelligent Insights** and wellness nudges

## 🔒 Privacy & Security

- **Zero data collection** - everything stays on device
- **AES-GCM 256-bit encryption** for all stored data
- **No cloud sync** - completely local storage
- **Keychain integration** for secure key management

## 📖 Documentation

- **[Detailed App Documentation](docs/README.md)** - Complete feature overview
- **[Model Training Guide](docs/CustomModelTraining.md)** - How to train custom models

## 🛠️ Development

### Core Technologies
- **SwiftUI** - Modern iOS interface
- **CoreML** - On-device machine learning
- **CoreData** - Local database with encryption
- **Natural Language** - Apple's NLP framework
- **CryptoKit** - AES-GCM encryption
- **WatchConnectivity** - Apple Watch integration
- **HealthKit** - Wellness data integration

### Model Performance
- **91.17% accuracy** on emotion classification
- **Real-time processing** under 100ms
- **Multi-language support** with 85%+ accuracy
- **Enhanced Apple NLP** as fallback

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

---

**SmartJournal** - Your private, intelligent mood companion. Built with ❤️ for privacy and mental wellness.
