#!/bin/bash

echo "🚀 SmartJournal Custom Model Setup"
echo "=================================="

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    echo "Please install Python 3 and try again."
    exit 1
fi

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is required but not installed."
    echo "Please install pip3 and try again."
    exit 1
fi

echo "✅ Python 3 found"

# Install required packages
echo "📦 Installing required Python packages..."
pip3 install pandas numpy tensorflow scikit-learn coremltools

if [ $? -eq 0 ]; then
    echo "✅ Python packages installed successfully"
else
    echo "❌ Failed to install Python packages"
    exit 1
fi

# Make the training script executable
chmod +x train_custom_model.py

echo ""
echo "🎯 Setup Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Download a Kaggle dataset:"
echo "   - Sentiment140: https://www.kaggle.com/datasets/kazanova/sentiment140"
echo "   - Emotion Dataset: https://www.kaggle.com/datasets/praveengovi/emotions-dataset-for-nlp"
echo ""
echo "2. Run the training script:"
echo "   python3 train_custom_model.py"
echo ""
echo "3. Add the generated files to your Xcode project:"
echo "   - SmartJournalSentiment.mlmodel"
echo "   - tokenizer_config.json"
echo ""
echo "4. Update your ContentView to use CustomSentimentAnalyzer"
echo ""
echo "📚 For detailed instructions, see CustomModelTraining.md"
