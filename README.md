# SillyTavern Native

A fully native Android/iOS companion app for AI character chat, with VRM 3D character rendering. No server required — connects directly to AI APIs.

> Inspired by the UI/UX of [AIRI](https://github.com/moeru-ai/airi). Built with Flutter.

---

## Features

- **100% standalone** — no SillyTavern server needed
- **Direct AI API** — OpenAI, Claude, Gemini, Ollama, OpenRouter
- **VRM characters** — Three.js + @pixiv/three-vrm via WebGL
- **Character cards** — compatible with SillyTavern JSON format
- **Secure storage** — API keys stored in device keychain
- **AIRI-inspired UI** — dark theme, smooth animations, clean layout
- **Markdown chat** — bold, italic, code blocks rendered natively
- **Procedural animation** — idle breathing, head sway, auto-blink

---

## Architecture

```
lib/
├── main.dart                  # Entry point
├── app.dart                   # Root widget + routing
├── theme/app_theme.dart       # Dark theme constants
├── models/
│   ├── ai_provider.dart       # OpenAI/Claude/Gemini/Ollama/OpenRouter
│   ├── character_model.dart   # Character card (ST-compatible JSON)
│   ├── message_model.dart     # Chat message
│   └── settings_model.dart    # App settings
├── services/
│   └── ai_service.dart        # Direct API calls (no middleware)
├── providers/                 # Riverpod state
│   ├── settings_provider.dart
│   ├── chat_provider.dart
│   ├── character_provider.dart
│   └── (ai providers)
├── screens/
│   ├── home_screen.dart       # Bottom nav shell
│   ├── chat_screen.dart       # VRM + chat UI
│   ├── characters_screen.dart # Character grid + import
│   ├── settings_screen.dart   # AI config + toggles
│   └── setup_screen.dart      # First-launch onboarding
└── widgets/
    ├── vrm_viewer.dart        # WebView wrapper for VRM
    ├── chat_bubble.dart       # User + AI bubbles (Markdown)
    └── message_input.dart     # Animated send input

assets/
└── html/vrm_viewer.html       # Three.js + @pixiv/three-vrm scene
```

---

## Supported AI Providers

| Provider | API Format | Notes |
|---|---|---|
| OpenAI | OpenAI Chat | GPT-4o, GPT-4-turbo |
| Anthropic | Messages API | Claude 3.5 Sonnet |
| Google Gemini | Gemini API | Gemini 1.5 Pro |
| OpenRouter | OpenAI-compat | Free models available |
| Ollama | OpenAI-compat | Local LLM, no key needed |

---

## Building

### Debug (no signing)

```bash
cd sillytavern-app
flutter pub get
flutter build apk --debug
```

### Release (GitHub Actions)

Push a tag to trigger a signed release build:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Required GitHub secrets for signed release:
- `ANDROID_KEYSTORE_BASE64` — keystore file as base64
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

---

## Character Import

Import characters in SillyTavern JSON format from the Characters tab. Fields supported:
- `name`, `description`, `personality`, `scenario`
- `first_mes` (first message), `system_prompt`
- `avatar`, `vrmPath`

---

## VRM Characters

1. Place `.vrm` files accessible via URL or local path
2. In Characters, set the VRM path for a character
3. Enable VRM in Settings → Display
4. The character appears in the chat header with idle animations
