# SmartJournal Model Training Scripts

This directory contains Python scripts for training custom sentiment analysis models for the SmartJournal app.

## 📋 Prerequisites

### Required Files (Not Included in Repository)
Due to file size limitations, the following files are **NOT** included in the repository:

1. **GloVe Embeddings** (2.97GB total)
   - Download from: https://nlp.stanford.edu/projects/glove/
   - Required files:
     - `glove.6B.100d.txt` (331MB) - For fast training
     - `glove.6B.300d.txt` (990MB) - For best accuracy
   - Place in project root directory

2. **Emotion Dataset**
   - `Emotion_final.csv` (2.2MB) - Already included in `data/` folder
   - Contains ~20K emotion-labeled text samples

## 🚀 Quick Start

### 1. Setup Environment
```bash
# Make setup script executable
chmod +x setup_custom_model.sh

# Install dependencies
./setup_custom_model.sh
```

### 2. Download GloVe Embeddings
```bash
# Download GloVe embeddings (choose one)
wget http://nlp.stanford.edu/data/glove.6B.zip
unzip glove.6B.zip

# Or download individual files
wget http://nlp.stanford.edu/data/glove.6B.100d.txt
```

### 3. Train Models

#### Fast Training (Recommended)
```bash
python fast_85_accuracy_model.py
```
- **Time:** ~2 minutes
- **Accuracy:** 91.17%
- **Requirements:** `glove.6B.100d.txt`

#### Advanced Ensemble
```bash
python advanced_ensemble_model.py
```
- **Time:** ~10-15 minutes
- **Accuracy:** 76.6%
- **Requirements:** `glove.6B.100d.txt`

#### Basic Training
```bash
python train_custom_model.py
```
- **Time:** ~5 minutes
- **Accuracy:** 55-65%
- **Requirements:** None (uses TF-IDF only)

### 4. Convert to CoreML
```bash
python convert_to_coreml.py
```
- Converts trained models to CoreML format
- Generates `.mlpackage` files for iOS integration

## 📊 Model Performance

| Script | Accuracy | Time | Features |
|--------|----------|------|----------|
| `fast_85_accuracy_model.py` | **91.17%** | 2 min | GloVe + TF-IDF + Smart Features |
| `advanced_ensemble_model.py` | 76.6% | 10-15 min | GloVe + Ensemble Methods |
| `train_custom_model.py` | 55-65% | 5 min | TF-IDF Only |

## 🔧 Integration with iOS App

After training and conversion:

1. **Copy the generated `.mlpackage` file** to your Xcode project
2. **Replace** `SmartJournal/SentimentClassifier.mlmodel` with your new model
3. **Update** `CustomSentimentAnalyzer.swift` if needed
4. **Test** the model in the iOS app

## 📁 Output Files

Training generates these files:
- `Fast85AccuracyModel_ensemble.joblib` - Trained ensemble model
- `Fast85AccuracyModel_glove.joblib` - GloVe embeddings
- `Fast85AccuracyModel_scaler.joblib` - Feature scaler
- `Fast85AccuracyModel_tfidf.joblib` - TF-IDF vectorizer
- `SentimentClassifier.mlpackage` - CoreML model (after conversion)

## ⚠️ Important Notes

- **GloVe files are large** (2.97GB total) - not included in repository
- **Models are already trained** - included in `models/` folder
- **iOS app works without retraining** - uses pre-trained models
- **Retraining is optional** - only needed for custom datasets

## 🆘 Troubleshooting

### Missing GloVe Files
```
FileNotFoundError: [Errno 2] No such file or directory: 'glove.6B.100d.txt'
```
**Solution:** Download GloVe embeddings from Stanford NLP website

### Memory Issues
```
MemoryError: Unable to allocate array
```
**Solution:** Use smaller GloVe file (50d or 100d instead of 300d)

### CoreML Conversion Issues
```
Error during conversion: Unable to determine the type of the model
```
**Solution:** Ensure all model files are present and properly trained

---

**Note:** The iOS app includes pre-trained models and works out-of-the-box. These scripts are for developers who want to retrain models with custom datasets.
