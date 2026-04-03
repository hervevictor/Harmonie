#!/bin/bash
# Lance Harmonie avec l'APK réduit (split par architecture) pour éviter INSUFFICIENT_STORAGE
flutter run --split-per-abi "$@"
