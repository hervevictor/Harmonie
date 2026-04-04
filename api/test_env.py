import sys

print("--- DIAGNOSTIC DES SERVICES IA ---")
print(f"Python version: {sys.version}")

try:
    import numpy
    print(f"✅ Numpy: {numpy.__version__}")
except ImportError:
    print("❌ Numpy: NON INSTALLÉ")

try:
    import librosa
    print(f"✅ Librosa: {librosa.__version__}")
except ImportError:
    print("❌ Librosa: NON INSTALLÉ")

try:
    import basic_pitch
    print("✅ Basic-Pitch: INSTALLÉ")
except ImportError:
    print("❌ Basic-Pitch: NON INSTALLÉ")

try:
    import music21
    print(f"✅ Music21: {music21.VERSION_STR}")
except ImportError:
    print("❌ Music21: NON INSTALLÉ")

try:
    import tensorflow as tf
    print(f"✅ TensorFlow: {tf.__version__}")
except ImportError:
    print("❌ TensorFlow: NON INSTALLÉ")
