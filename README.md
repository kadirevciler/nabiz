# Nabız — Mac hızlandırıcı ve güvenlik asistanı

**🇹🇷 Türkçe** · [🇬🇧 English](#english)

Nabız, Mac'inizin performansını ve güvenliğini canlı izleyen, yapılması gerekenleri sade bir dille öneren ve gereksiz dosyaları **yalnızca sizin onayınızla** temizleyen, yerel (native) bir macOS uygulamasıdır. SwiftUI ile yazıldı; tamamen çevrimdışı çalışır.

## Özellikler

- **Genel Bakış** — 0–100 sistem sağlığı puanı, işlemci, bellek, disk ve pil halkaları.
- **Hızlandır (⚡)** — Tek dokunuşla analiz: ağır uygulamaları bulur, güvenliği denetler, gereksiz dosyaları tarar, önerileri sıralar.
- **Performans** — Canlı grafikler: çekirdek başına işlemci, bellek baskısı ve takas, ağ hızı, disk, ısı, pil sağlığı, en çok işlemci kullanan süreçler.
- **Güvenlik** — FileVault, SIP, Gatekeeper, güvenlik duvarı ve gizli mod, otomatik ve bekleyen güncellemeler, ekran kilidi, otomatik giriş, misafir hesabı, SSH / ekran / dosya paylaşımı, arka plan öğeleri. Her bulgunun yanında ilgili Sistem Ayarları sayfasını açan simge bulunur.
- **Öneriler** — Kritik / Uyarı / İpucu düzeyinde, tek simgeyle uygulanabilir öneriler.
- **Temizlik** — Önbellekler, günlükler, geliştirici artıkları (Xcode DerivedData vb.), eski .dmg/.pkg yükleyiciler, büyük ve eski indirmeler, Çöp Sepeti. Dosyalar **Çöp Sepeti'ne taşınır**, geri alınabilir. Her silme işleminden önce ayrıntılı onay penceresi çıkar.
- **AI Analizi** — İki seçenek: (1) **OpenAI, Claude, Gemini, DeepSeek, GLM (Z.ai) veya OpenRouter** API anahtarınızı ve model adını girin, sistemi seçtiğiniz model analiz etsin (anahtar macOS Anahtar Zinciri'nde saklanır); (2) yapay zekâ için düzenlenmiş **durum raporunu** kopyalayın, .md / .json kaydedin veya tek tıkla ChatGPT, Claude, Gemini vb. açıp yapıştırın.
- **Yardım** — Yardım menüsünden veya **?** simgesinden açılır, konu bazlı arama yapılır (Türkçe karakter duyarsız, iki dilde).
- **Türkçe / İngilizce** — Kenar çubuğundaki 🌐 simgesi, *Dil* menüsü veya **⇧⌘L** ile anında geçiş.

## Gereksinimler

- macOS 14 Sonoma veya üzeri
- Apple Silicon veya Intel Mac (hazır paket Apple Silicon içindir; Intel'de kaynaktan derleyin)

## Kurulum

### Yöntem 1 — Hazır uygulama (önerilen, en kolayı)

1. [Releases](https://github.com/kadirevciler/nabiz/releases/latest) sayfasından **Nabiz-macOS.zip** dosyasını indirin.
2. İndirilenler klasöründe zip dosyasına çift tıklayın; **Nabız.app** çıkar.
3. **Nabız.app**'i **Uygulamalar** (Applications) klasörüne sürükleyin.
4. İlk açılış: Uygulama Apple'ın ücretli geliştirici sertifikasıyla imzalanmadığı için macOS ilk seferde uyarı verir. Şunlardan birini yapın:
   - **Uygulamalar** klasöründe **Nabız**'a **sağ tıklayın → Aç**, çıkan pencerede yeniden **Aç**'a basın; **veya**
   - Açmayı bir kez deneyin, sonra **Sistem Ayarları → Gizlilik ve Güvenlik**'e gidin, aşağıdaki *"Nabız engellendi"* satırında **Yine de Aç**'a basın; **veya**
   - Terminal'de şu komutu çalıştırın, ardından normal açın:
     ```bash
     xattr -dr com.apple.quarantine /Applications/Nabız.app
     ```
5. Bu işlem yalnızca bir kez gerekir. Sonraki açılışlar normaldir.

### Yöntem 2 — Kaynaktan derleme

1. Xcode veya Command Line Tools kurulu olmalı:
   ```bash
   xcode-select --install
   ```
2. Depoyu indirin ve derleyin:
   ```bash
   git clone https://github.com/kadirevciler/nabiz.git
   cd nabiz
   ./scripts/build_app.sh
   ```
3. Uygulama `build/Nabız.app` olarak oluşur. Uygulamalar klasörüne kopyalayın:
   ```bash
   cp -R build/Nabız.app /Applications/
   ```
   Kendiniz derlediğiniz için karantina uyarısı çıkmaz.

## İsteğe bağlı izinler

- **İndirilenler klasörü** — Eski yükleyicileri bulmak için ilk taramada macOS izin ister; *İzin Ver* deyin.
- **Tam Disk Erişimi** — Çöp Sepeti'ni tarayabilmek için gerekir: *Sistem Ayarları → Gizlilik ve Güvenlik → Tam Disk Erişimi → Nabız*'ı açın, Nabız'ı yeniden başlatın. Vermezseniz diğer kategoriler yine çalışır.

## Güvenlik ve gizlilik

- Siz **AI analizi** başlatmadıkça hiçbir veri Mac'inizin dışına gönderilmez. AI analizinde durum raporu yalnızca seçtiğiniz sağlayıcıya gider ve bilgisayar adı, kullanıcı adı ya da dosya adı içermez. Diğer tek ağ isteği, macOS'un kendi `softwareupdate` aracının güncelleme sormasıdır.
- API anahtarları macOS Anahtar Zinciri'nde saklanır.
- Güvenlik denetimleri salt okunurdur; hiçbir ayar sizin yerinize değiştirilmez. Simgeler sadece ilgili ayar sayfasını açar.
- Temizlik dosyaları Çöp Sepeti'ne taşır. Yalnızca *Çöp Sepeti* kategorisini seçerseniz kalıcı silme yapılır ve onay penceresi bunu kırmızı uyarıyla belirtir.
- "Ağır uygulamaları kapat" normal *Çık* komutu gönderir (⌘Q gibi); kaydedilmemiş iş varsa uygulama size sorar.

## Kısayollar

| Kısayol | İşlev |
|---|---|
| ⌘1 – ⌘6 | Bölümler arası geçiş |
| ⇧⌘B | Hızlandır |
| ⌘R | Tümünü yenile |
| ⇧⌘S | Güvenlik taraması |
| ⇧⌘K | Gereksiz dosya taraması |
| ⇧⌘L | Dili değiştir |
| ⌘? | Yardım |

## Kaldırma

**Nabız.app**'i Uygulamalar klasöründen Çöp Sepeti'ne sürükleyin. Dil tercihini de silmek için:
```bash
defaults delete com.kadir.nabiz
```

---

<a id="english"></a>
# Nabız — Mac booster and security assistant

Nabız is a native macOS app that monitors your Mac's performance and security live, explains what to do in plain language, and cleans junk files **only with your approval**. Built with SwiftUI; works fully offline.

## Features

- **Overview** — 0–100 health score with CPU, memory, disk and battery rings.
- **Boost (⚡)** — One-tap analysis: finds heavy apps, audits security, scans junk, ranks advice.
- **Performance** — Live per-core CPU, memory pressure & swap, network, disk, thermal state, battery health, top processes.
- **Security** — FileVault, SIP, Gatekeeper, firewall & stealth mode, automatic and pending updates, screen lock, automatic login, guest account, SSH / screen / file sharing, background items — each with a shortcut to the right System Settings page.
- **Advice** — Critical / Warning / Tip, each actionable with a single icon.
- **Cleanup** — Caches, logs, developer leftovers, old installers, large old downloads, Trash. Files are **moved to the Trash** (recoverable) after a detailed confirmation.
- **AI Analysis** — Two options: (1) enter an **OpenAI, Claude, Gemini, DeepSeek, GLM (Z.ai) or OpenRouter** API key and a model name and let that model analyze your system (keys live in the macOS Keychain); (2) copy the AI-ready **status report**, save it as .md / .json, or open ChatGPT, Claude, Gemini etc. in one click and paste it.
- **Help** — From the Help menu or the **?** icon, with topic search in both languages.
- **Turkish / English** — Switch instantly with the 🌐 icon, the *Language* menu, or **⇧⌘L**.

## Requirements

macOS 14 Sonoma or later. The prebuilt package targets Apple Silicon; build from source on Intel.

## Installation

### Option 1 — Prebuilt app (recommended)

1. Download **Nabiz-macOS.zip** from [Releases](https://github.com/kadirevciler/nabiz/releases/latest).
2. Double-click the zip in Downloads to get **Nabız.app**.
3. Drag **Nabız.app** into **Applications**.
4. First launch: the app is not signed with a paid Apple Developer certificate, so macOS warns the first time. Either:
   - **Right-click Nabız → Open**, then **Open** again; **or**
   - try to open it once, then go to **System Settings → Privacy & Security** and click **Open Anyway**; **or**
   - run in Terminal, then open normally:
     ```bash
     xattr -dr com.apple.quarantine /Applications/Nabız.app
     ```
5. This is only needed once.

### Option 2 — Build from source

```bash
xcode-select --install          # if you don't have the tools yet
git clone https://github.com/kadirevciler/nabiz.git
cd nabiz
./scripts/build_app.sh
cp -R build/Nabız.app /Applications/
```

## Optional permissions

- **Downloads folder** — macOS asks on the first scan; click *Allow*.
- **Full Disk Access** — needed to scan the Trash: *System Settings → Privacy & Security → Full Disk Access → Nabız*, then restart Nabız.

## Privacy & safety

No data leaves your Mac unless you start an **AI analysis**; then the status report (no computer, user or file names) goes only to the provider you chose. API keys are stored in the macOS Keychain. Security checks are read-only and never change settings for you. Cleanup moves files to the Trash; only the *Trash* category deletes permanently, with a red warning. Quitting heavy apps sends a normal Quit (like ⌘Q).

## Uninstall

Drag **Nabız.app** to the Trash. To remove the saved language preference: `defaults delete com.kadir.nabiz`
