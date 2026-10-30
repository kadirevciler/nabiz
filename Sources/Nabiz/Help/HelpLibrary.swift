import Foundation

struct HelpTopic: Identifiable, Hashable {
    let id: String
    let category: String
    let icon: String
    let title: String
    let keywords: String
    let body: String
    var related: [String] = []
}

enum HelpLibrary {
    static var categories: [String] { [C.start, C.boost, C.perf, C.sec, C.clean, C.ai, C.trouble] }

    private enum C {
        static var start: String { L("Başlarken", "Getting Started") }
        static var boost: String { L("Hızlandırma", "Speeding Up") }
        static var perf: String { L("Performans", "Performance") }
        static var sec: String { L("Güvenlik", "Security") }
        static var clean: String { L("Temizlik", "Cleanup") }
        static var ai: String { L("Yapay Zekâ", "AI") }
        static var trouble: String { L("Sorun Giderme", "Troubleshooting") }
    }

    static func topic(_ id: String) -> HelpTopic? { topics.first { $0.id == id } }

    static var topics: [HelpTopic] { [
        .init(id: "nabiz-nedir", category: C.start, icon: "waveform.path.ecg", title: L("Nabız nedir?", "What is Nabız?"),
              keywords: "hakkında giriş tanıtım başlangıç about intro overview",
              body: L("""
Nabız, Mac'inizin performansını ve güvenliğini sürekli izleyen, yapılması gerekenleri sade bir dille öneren bir yardımcıdır.

• **Genel Bakış**: Sistem sağlığı puanı ve temel ölçümler.
• **Performans**: Canlı işlemci, bellek, disk, ağ ve ısı grafikleri.
• **Güvenlik**: macOS koruma ayarlarının denetimi.
• **Öneriler**: Yapılacaklar listesi, önem sırasına göre.
• **Temizlik**: Gereksiz dosyaları bulma ve onayınızla temizleme.

Nabız hiçbir veriyi internete göndermez; tüm denetimler Mac'inizde yapılır.
""", """
Nabız is an assistant that continuously watches your Mac's performance and security and tells you, in plain language, what to do.

• **Overview**: System health score and key metrics.
• **Performance**: Live CPU, memory, disk, network and thermal charts.
• **Security**: An audit of macOS protection settings.
• **Advice**: A to-do list ordered by importance.
• **Cleanup**: Find junk files and clean them with your approval.

Nabız never sends data to the internet; every check runs on your Mac.
"""), related: ["arayuz", "saglik-puani", "hizlandir"]),
        .init(id: "arayuz", category: C.start, icon: "hand.point.up.left.fill", title: L("Simgeler ve arayüz", "Icons and interface"),
              keywords: "düğme buton simge ikon ipucu menü kenar çubuğu dil button icon tooltip menu sidebar language",
              body: L("""
Nabız'da düğmeler sade tutuldu; çoğu yalnızca bir simgedir. Ne yaptığını görmek için fareyi simgenin üzerinde bir an bekletin, kısa bir açıklama çıkar.

• Sol kenardaki simgeler bölümler arasında geçiş yapar (⌘1 – ⌘6).
• Sarı **şimşek** simgesi tek dokunuşla **Hızlandır** analizini başlatır.
• **Dünya** simgesi dili Türkçe ile İngilizce arasında değiştirir.
• **Soru işareti** bu yardım penceresini açar.
• **Dişli** simgesi ilgili Sistem Ayarları sayfasını açar.
• **Döngü ok** simgesi taramayı yeniler.
""", """
Buttons in Nabız are kept minimal; most are just an icon. Hover over an icon for a moment to see a short description.

• Icons on the left edge switch between sections (⌘1 – ⌘6).
• The yellow **bolt** starts the one-tap **Boost** analysis.
• The **globe** switches the language between Turkish and English.
• The **question mark** opens this help window.
• The **gear** opens the related System Settings page.
• The **circular arrow** refreshes a scan.
"""), related: ["kisayollar"]),
        .init(id: "saglik-puani", category: C.start, icon: "heart.text.square.fill", title: L("Sistem sağlığı puanı", "System health score"),
              keywords: "skor puan sağlık hesaplama yüzde score health calculation percent",
              body: L("""
Sağlık puanı 0–100 arasıdır ve iki eşit parçadan oluşur:

• **Güvenlik puanı**: Her denetimin bir ağırlığı vardır. Tamam olanlar tam puan, uyarılar yarım puan alır.
• **Performans puanı**: Yüksek işlemci yükü, bellek baskısı, takas kullanımı, az disk alanı, ısınma ve uzun süre yeniden başlatılmama puanı düşürür.

90 üstü **Harika**, 75 üstü **İyi**, 55 üstü **Bakım gerekli**, altı **Dikkat** demektir.
""", """
The health score ranges from 0 to 100 and has two equal parts:

• **Security score**: Each check has a weight. Passing checks get full points, warnings get half.
• **Performance score**: High CPU load, memory pressure, swap usage, low disk space, heat and a long time without restart lower the score.

Above 90 is **Excellent**, above 75 **Good**, above 55 **Needs care**, below that **Attention**.
"""), related: ["oneriler"]),
        .init(id: "kisayollar", category: C.start, icon: "command", title: L("Klavye kısayolları", "Keyboard shortcuts"),
              keywords: "kısayol klavye tuş komut shortcut keyboard key command",
              body: L("""
• **⌘1 – ⌘6**: Bölümler arasında geçiş
• **⌘R**: Tüm ölçümleri yenile
• **⇧⌘S**: Güvenlik taramasını yeniden başlat
• **⇧⌘K**: Gereksiz dosya taraması
• **⇧⌘B**: Hızlandır
• **⇧⌘L**: Dili değiştir
• **⌘?**: Yardım
""", """
• **⌘1 – ⌘6**: Switch sections
• **⌘R**: Refresh all metrics
• **⇧⌘S**: Rerun the security scan
• **⇧⌘K**: Junk file scan
• **⇧⌘B**: Boost
• **⇧⌘L**: Switch language
• **⌘?**: Help
""")),
        .init(id: "hizlandir", category: C.boost, icon: "bolt.fill", title: L("Hızlandır nasıl çalışır?", "How does Boost work?"),
              keywords: "hızlandır hızlandırma yavaş optimize tek tık boost speed up slow optimize one click",
              body: L("""
**Hızlandır** düğmesi (sarı şimşek) Mac'inizi tek seferde analiz eder:

1. Belleği en çok kullanan açık uygulamaları bulur.
2. Güvenlik ayarlarını yeniden denetler.
3. Gereksiz dosyaları tarar.
4. Önerileri önem sırasına koyar.

Sonuçta her adım için tek bir simge görürsünüz. Hiçbir işlem siz onaylamadan yapılmaz: uygulamaları siz kapatırsınız, dosyaları temizlik ekranında siz seçip onaylarsınız.
""", """
The **Boost** button (yellow bolt) analyzes your Mac in one go:

1. Finds the open apps using the most memory.
2. Re-checks security settings.
3. Scans for junk files.
4. Orders advice by importance.

Each result comes with a single icon. Nothing happens without your approval: you quit the apps yourself, and you select and confirm files on the Cleanup screen.
"""), related: ["agir-uygulamalar", "temizlik-nasil"]),
        .init(id: "agir-uygulamalar", category: C.boost, icon: "power", title: L("Ağır uygulamaları kapatmak", "Quitting heavy apps"),
              keywords: "uygulama kapat bellek ram dondu yavaş app quit memory frozen slow",
              body: L("""
Hızlandır ekranı 150 MB'tan fazla bellek veya yoğun işlemci kullanan açık uygulamaları listeler. **Güç** simgesi uygulamaya normal “Çık” komutu gönderir — tıpkı ⌘Q gibi.

Kaydedilmemiş belgeniz varsa uygulama kaydetmek isteyip istemediğinizi sorar; zorla kapatma yapılmaz.
""", """
The Boost screen lists open apps using more than 150 MB of memory or heavy CPU. The **power** icon sends the app a normal “Quit” command — just like ⌘Q.

If you have unsaved documents the app asks whether to save; nothing is force-quit.
"""), related: ["bellek"]),
        .init(id: "yeniden-baslat", category: C.boost, icon: "restart.circle.fill", title: L("Neden yeniden başlatmalıyım?", "Why should I restart?"),
              keywords: "yeniden başlat restart kapat aç uptime çalışma süresi reboot",
              body: L("""
Mac'ler uzun süre uyku moduyla çalışabilir, ama zamanla bellek parçalanır, arka plan işlemleri birikir ve bekleyen güncellemeler uygulanmaz. Haftada bir yeniden başlatmak çoğu yavaşlığı giderir. Nabız, Mac 7 günden uzun süredir açıksa bunu önerir.
""", """
Macs can run on sleep for a long time, but memory fragments, background processes pile up and pending updates are not applied. Restarting once a week fixes most slowdowns. Nabız suggests it when your Mac has been up for more than 7 days.
""")),
        .init(id: "cpu", category: C.perf, icon: "cpu", title: L("İşlemci (CPU) kullanımı", "CPU usage"),
              keywords: "işlemci cpu çekirdek yük load fan processor core",
              body: L("""
İşlemci kartı son 90 saniyelik kullanımı ve her çekirdeğin anlık yükünü gösterir. Kısa süreli tepeler normaldir. Kullanım uzun süre %80'in üzerinde kalıyorsa bir uygulama takılmış olabilir.

**Yük** değerleri son 1, 5 ve 15 dakikanın ortalamasıdır; çekirdek sayısının altında kalması iyidir. **Etkinlik Monitörü** simgesiyle ayrıntıya inebilirsiniz.
""", """
The CPU card shows usage over the last 90 seconds and the live load of each core. Short spikes are normal. If usage stays above 80% for long, an app may be stuck.

**Load** values are the averages of the last 1, 5 and 15 minutes; staying below the core count is good. Use the **Activity Monitor** icon to dig deeper.
"""), related: ["agir-uygulamalar", "isi"]),
        .init(id: "bellek", category: C.perf, icon: "memorychip", title: L("Bellek ve bellek baskısı", "Memory and memory pressure"),
              keywords: "bellek ram memory baskı pressure sıkıştırma compression",
              body: L("""
macOS boş belleği önbellek için kullanır, bu yüzden “dolu görünen” bellek tek başına sorun değildir. Asıl ölçü **bellek baskısıdır**:

• **Normal**: Her şey yolunda.
• **Yüksek**: macOS belleği sıkıştırıyor; birkaç uygulamayı kapatın.
• **Kritik**: Mac yavaşlıyor; uygulamaları kapatın veya yeniden başlatın.

**Uygulama** belleği açık programlarındır, **Sabit** belleği sistem kullanır, **Sıkıştırılmış** bellek yer açmak için küçültülmüş verilerdir.
""", """
macOS uses free memory for caching, so memory that “looks full” is not a problem by itself. The real measure is **memory pressure**:

• **Normal**: All good.
• **High**: macOS is compressing memory; quit a few apps.
• **Critical**: Your Mac is slowing down; quit apps or restart.

**App** memory belongs to open programs, **Wired** memory is used by the system, **Compressed** memory is data shrunk to make room.
"""), related: ["swap", "agir-uygulamalar"]),
        .init(id: "swap", category: C.perf, icon: "arrow.left.arrow.right", title: L("Takas (swap) alanı", "Swap space"),
              keywords: "takas swap sanal bellek disk virtual memory",
              body: L("""
Bellek yetmediğinde macOS verilerin bir kısmını diske yazar; buna takas denir. Disk bellekten çok daha yavaş olduğu için yüksek takas (2 GB üstü) Mac'in yavaşladığının işaretidir. Uygulamaları kapatmak veya yeniden başlatmak takası sıfırlar.
""", """
When memory runs short, macOS writes some data to disk; this is called swap. Because disk is much slower than memory, high swap (over 2 GB) is a sign your Mac is slowing down. Quitting apps or restarting resets swap.
"""), related: ["bellek"]),
        .init(id: "disk", category: C.perf, icon: "internaldrive", title: L("Disk alanı", "Disk space"),
              keywords: "disk depolama alan dolu ssd yer storage full space",
              body: L("""
macOS'un rahat çalışması için diskin en az %15–20'si boş kalmalıdır. Disk dolduğunda takas, güncellemeler ve önbellekler için yer kalmaz ve Mac belirgin şekilde yavaşlar.

Yer açmak için **Temizlik** bölümünü kullanın veya Sistem Ayarları › Genel › Depolama'daki önerilere bakın.
""", """
For macOS to run comfortably, at least 15–20% of the disk should stay free. When the disk fills up there is no room for swap, updates and caches, and your Mac slows down noticeably.

Use the **Cleanup** section to free space, or see the suggestions in System Settings › General › Storage.
"""), related: ["temizlik-nasil"]),
        .init(id: "pil", category: C.perf, icon: "battery.75percent", title: L("Pil sağlığı", "Battery health"),
              keywords: "pil batarya şarj döngü kapasite sağlık battery charge cycle capacity",
              body: L("""
**Sağlık**, pilin şu anki tam kapasitesinin fabrika kapasitesine oranıdır. %80'in altına düştüğünde pil süresi belirgin kısalır ve Apple servis önerir.

**Döngü**, toplam tam şarj sayısıdır. Pili uzun süre %100'de tutmamak için Sistem Ayarları › Pil › Optimize Edilmiş Şarj'ı açık tutun.
""", """
**Health** is the battery's current full capacity compared to its design capacity. Below 80% battery life drops noticeably and Apple recommends service.

**Cycles** is the total number of full charges. Keep System Settings › Battery › Optimized Charging on to avoid sitting at 100% for long.
""")),
        .init(id: "isi", category: C.perf, icon: "thermometer.medium", title: L("Isı durumu", "Thermal state"),
              keywords: "ısı sıcaklık termal fan ısınma heat temperature thermal",
              body: L("""
macOS ısı durumunu dört seviyede bildirir: **Normal, Ilık, Sıcak, Kritik**. Sıcak ve üzeri seviyelerde işlemci kendini yavaşlatır. Havalandırma deliklerini açık tutun, Mac'i yumuşak yüzeylerde kullanmayın ve yoğun işleri azaltın.
""", """
macOS reports four thermal levels: **Normal, Warm, Hot, Critical**. At Hot and above the CPU throttles itself. Keep the vents clear, avoid soft surfaces and reduce heavy work.
""")),
        .init(id: "ag", category: C.perf, icon: "network", title: L("Ağ trafiği", "Network traffic"),
              keywords: "ağ internet indirme yükleme wifi network hız download upload speed",
              body: L("""
Ağ kartı tüm bağlantılardaki anlık indirme (aşağı ok) ve yükleme (yukarı ok) hızını gösterir. Hiçbir şey yapmadığınız halde sürekli yüksek trafik görüyorsanız arka planda bulut eşitlemesi veya güncelleme çalışıyor olabilir.
""", """
The Network card shows live download (down arrow) and upload (up arrow) speed across all connections. If you see constant heavy traffic while doing nothing, cloud sync or an update may be running in the background.
""")),
        .init(id: "filevault", category: C.sec, icon: "lock.doc.fill", title: L("FileVault disk şifreleme", "FileVault disk encryption"),
              keywords: "filevault şifreleme encryption disk çalınma stolen",
              body: L("""
FileVault diskteki her şeyi şifreler. Mac'iniz kaybolur veya çalınırsa parolanız olmadan verileriniz okunamaz. Apple Silicon Mac'lerde performansa etkisi yoktur.

Açmak için: Sistem Ayarları › Gizlilik ve Güvenlik › FileVault. Kurtarma anahtarını güvenli bir yerde saklayın.
""", """
FileVault encrypts everything on the disk. If your Mac is lost or stolen, your data cannot be read without your password. It has no performance impact on Apple Silicon Macs.

To turn it on: System Settings › Privacy & Security › FileVault. Keep the recovery key somewhere safe.
""")),
        .init(id: "sip", category: C.sec, icon: "shield.lefthalf.filled", title: L("Sistem Bütünlüğü Koruması (SIP)", "System Integrity Protection (SIP)"),
              keywords: "sip csrutil sistem bütünlüğü koruma rootless system integrity protection",
              body: L("""
SIP, macOS sistem dosyalarının kötü amaçlı yazılımlar tarafından değiştirilmesini engeller. Normalde her zaman açık olmalıdır.

Kapalıysa yeniden açmak için Mac'i Kurtarma modunda başlatın, Terminal'i açın ve **csrutil enable** komutunu çalıştırıp yeniden başlatın.
""", """
SIP prevents malware from modifying macOS system files. It should normally always be on.

If it is off, start your Mac in Recovery mode, open Terminal, run **csrutil enable** and restart.
""")),
        .init(id: "gatekeeper", category: C.sec, icon: "checkmark.shield.fill", title: L("Gatekeeper", "Gatekeeper"),
              keywords: "gatekeeper uygulama imza geliştirici spctl indirme app signature developer download",
              body: L("""
Gatekeeper, internetten indirilen uygulamaların Apple tarafından onaylanmış geliştiricilerden geldiğini doğrular. Kapalıysa zararlı uygulamalar uyarı olmadan açılabilir. Ayar Sistem Ayarları › Gizlilik ve Güvenlik altındadır.
""", """
Gatekeeper verifies that apps downloaded from the internet come from developers approved by Apple. When it is off, harmful apps can open without warning. The setting is under System Settings › Privacy & Security.
""")),
        .init(id: "firewall", category: C.sec, icon: "flame.fill", title: L("Güvenlik duvarı ve gizli mod", "Firewall and stealth mode"),
              keywords: "firewall güvenlik duvarı gizli mod stealth ağ wifi network",
              body: L("""
Güvenlik duvarı, Mac'inize dışarıdan gelen istenmeyen bağlantıları engeller. Kafe, otel gibi ortak ağlarda özellikle önemlidir.

**Gizli mod** açıkken Mac'iniz ağ taramalarına yanıt vermez, böylece ağda daha az görünür olur. İkisi de Sistem Ayarları › Ağ › Güvenlik Duvarı altındadır.
""", """
The firewall blocks unwanted incoming connections to your Mac. It matters most on public networks such as cafés and hotels.

With **stealth mode** on, your Mac does not answer network probes, making it less visible. Both are under System Settings › Network › Firewall.
""")),
        .init(id: "guncelleme", category: C.sec, icon: "arrow.triangle.2.circlepath", title: L("Yazılım güncellemeleri", "Software updates"),
              keywords: "güncelleme update yama macos sürüm patch version",
              body: L("""
Güncellemeler güvenlik açıklarını kapatır ve performans iyileştirmeleri getirir. Sistem Ayarları › Genel › Yazılım Güncelleme › Otomatik Güncellemeler bölümünde **Güvenlik Yanıtlarını ve sistem dosyalarını yükle** seçeneğini açık tutun.

Nabız bekleyen güncellemeleri Apple sunucusuna sorarak kontrol eder; bu denetim bir dakika kadar sürebilir.
""", """
Updates close security holes and bring performance improvements. In System Settings › General › Software Update › Automatic Updates, keep **Install Security Responses and system files** on.

Nabız checks for pending updates by asking Apple's server; this can take up to a minute.
""")),
        .init(id: "ekran-kilidi", category: C.sec, icon: "lock.display", title: L("Ekran kilidi parolası", "Screen lock password"),
              keywords: "ekran kilidi parola şifre uyku ekran koruyucu screen lock password sleep screensaver",
              body: L("""
Mac uykuya geçtiğinde veya ekran koruyucu başladığında parola istenmesi, masanızdan kalktığınızda başkalarının Mac'inize erişmesini önler. En iyisi **hemen** ya da en geç 5 dakika sonra istenmesidir. Ayar: Sistem Ayarları › Kilit Ekranı.
""", """
Requiring a password when your Mac sleeps or the screen saver starts keeps others out when you step away. Best is **immediately**, or at most after 5 minutes. Setting: System Settings › Lock Screen.
""")),
        .init(id: "otomatik-giris", category: C.sec, icon: "person.badge.key.fill", title: L("Otomatik giriş ve misafir hesabı", "Automatic login and guest account"),
              keywords: "otomatik giriş auto login misafir guest kullanıcı user",
              body: L("""
Otomatik giriş açıkken Mac parola sormadan açılır; FileVault'un koruması da zayıflar. Misafir hesabı ise herkesin Mac'inizi kullanmasına izin verir. İkisini de Sistem Ayarları › Kullanıcılar ve Gruplar'dan kapatabilirsiniz.
""", """
With automatic login on, your Mac starts without a password, weakening FileVault's protection. A guest account lets anyone use your Mac. Turn both off in System Settings › Users & Groups.
""")),
        .init(id: "uzaktan-erisim", category: C.sec, icon: "network.badge.shield.half.filled", title: L("Uzaktan erişim ve paylaşım", "Remote access and sharing"),
              keywords: "ssh uzaktan giriş ekran paylaşımı dosya paylaşımı smb vnc remote login screen sharing file sharing",
              body: L("""
**Uzaktan giriş (SSH)**, **Ekran paylaşımı** ve **Dosya paylaşımı** başka cihazların Mac'inize bağlanmasına izin verir. Kullanmıyorsanız kapatın; açık her kapı bir saldırı yüzeyidir. Ayarlar: Sistem Ayarları › Genel › Paylaşma.
""", """
**Remote Login (SSH)**, **Screen Sharing** and **File Sharing** let other devices connect to your Mac. Turn them off if you don't use them; every open door is attack surface. Settings: System Settings › General › Sharing.
""")),
        .init(id: "arka-plan-ogeleri", category: C.sec, icon: "gearshape.2.fill", title: L("Arka plan ve giriş öğeleri", "Background and login items"),
              keywords: "arka plan giriş öğeleri başlangıç launch agent daemon açılış background login items startup",
              body: L("""
Bazı uygulamalar açılışta kendiliğinden başlayan arka plan bileşenleri kurar. Bunlar açılışı yavaşlatabilir ve nadiren kötü amaçlı olabilir. Tanımadığınız öğeleri Sistem Ayarları › Genel › Giriş Öğeleri ve Uzantılar bölümünden kapatın.
""", """
Some apps install background components that start automatically at login. They can slow startup and are occasionally malicious. Turn off items you don't recognize in System Settings › General › Login Items & Extensions.
""")),
        .init(id: "temizlik-nasil", category: C.clean, icon: "sparkles", title: L("Temizlik nasıl çalışır?", "How does Cleanup work?"),
              keywords: "temizlik temizle gereksiz dosya önbellek cache log silme yer aç cleanup clean junk delete free space",
              body: L("""
1. Büyük **büyüteç** simgesine tıklayarak taramayı başlatın.
2. Nabız şunları bulur: uygulama önbellekleri, günlük dosyaları, geliştirici artıkları, eski .dmg/.pkg yükleyiciler, büyük ve eski indirmeler, Çöp Sepeti.
3. Kategorileri veya tek tek dosyaları seçin. **Ok** simgesiyle ayrıntıları açın, **büyüteç** ile dosyayı Finder'da görün.
4. Alttaki kırmızı **çöp** simgesine tıklayın; ne silineceğini gösteren bir onay penceresi açılır.

Onay vermeden hiçbir dosyaya dokunulmaz.
""", """
1. Click the large **magnifying glass** to start the scan.
2. Nabız finds: app caches, log files, developer leftovers, old .dmg/.pkg installers, large old downloads and the Trash.
3. Select categories or individual files. Use the **arrow** to expand details and the **magnifying glass** to reveal a file in Finder.
4. Click the red **trash** icon at the bottom; a confirmation window shows exactly what will be removed.

No file is touched without your confirmation.
"""), related: ["temizlik-guvenli-mi", "tam-disk-erisimi"]),
        .init(id: "temizlik-guvenli-mi", category: C.clean, icon: "arrow.uturn.backward.circle", title: L("Silinen dosyalar nereye gider?", "Where do deleted files go?"),
              keywords: "geri al geri yükle çöp sepeti güvenli kalıcı silme undo restore trash safe permanent",
              body: L("""
Temizlenen dosyalar **Çöp Sepeti'ne taşınır**, kalıcı silinmez. Yanlışlıkla bir şey sildiyseniz Çöp Sepeti'ni açıp **Geri Koy** diyebilirsiniz. Disk alanı, Çöp Sepeti boşaltıldığında açılır.

Tek istisna **Çöp Sepeti** kategorisidir: onu seçerseniz içindekiler kalıcı olarak silinir. Bu durumda onay penceresi kırmızı bir uyarı gösterir.

Önbellekler güvenle silinebilir; uygulamalar gerektiğinde yeniden oluşturur. İlk açılış biraz yavaş olabilir.
""", """
Cleaned files are **moved to the Trash**, not deleted permanently. If you removed something by mistake, open the Trash and choose **Put Back**. Disk space is freed when the Trash is emptied.

The only exception is the **Trash** category: if you select it, its contents are deleted permanently. The confirmation window then shows a red warning.

Caches are safe to delete; apps rebuild them when needed. The first launch may be a little slower.
""")),
        .init(id: "tam-disk-erisimi", category: C.clean, icon: "lock.trianglebadge.exclamationmark", title: L("Tam Disk Erişimi izni", "Full Disk Access permission"),
              keywords: "izin tam disk erişimi full disk access okunamadı erişim reddedildi permission denied",
              body: L("""
macOS bazı klasörleri (ör. Çöp Sepeti) uygulamalardan korur. Bu klasörleri tarayabilmek için Nabız'a izin vermeniz gerekir:

Sistem Ayarları › Gizlilik ve Güvenlik › Tam Disk Erişimi › Nabız'ı açın, ardından Nabız'ı yeniden başlatın.

İzin vermek istemezseniz diğer kategoriler yine çalışır.
""", """
macOS protects some folders (e.g. the Trash) from apps. To scan them, Nabız needs your permission:

System Settings › Privacy & Security › Full Disk Access › turn on Nabız, then restart Nabız.

If you prefer not to grant it, the other categories still work.
""")),
        .init(id: "ai-api", category: C.ai, icon: "key.horizontal.fill", title: L("API anahtarıyla AI analizi", "AI analysis with an API key"),
              keywords: "yapay zeka ai api anahtar key model openai chatgpt claude anthropic gemini google deepseek glm zai zhipu openrouter analiz analysis keychain",
              body: L("""
**AI Analizi** bölümünde (⌘6) **API ile analiz** modunu seçin:

1. Sağlayıcının logosuna tıklayın: **OpenAI, Claude, Gemini, DeepSeek, GLM (Z.ai)** veya **OpenRouter**.
2. **Anahtar al** simgesi sağlayıcının anahtar sayfasını açar. Anahtarı oluşturup kopyalayın.
3. Anahtarı alana yapıştırın ve **onay** simgesine basın. Anahtar macOS **Anahtar Zinciri**'nde şifreli saklanır; dosyaya yazılmaz. Kayıtlı anahtarı olan sağlayıcıda yeşil anahtar rozeti görünür.
4. **Model adını** yazın (örn. claude-opus-5-5, gpt-5, gemini-2.5-pro, deepseek-chat, glm-4.6). **Sihirli değnek** simgesi önerilen modeli yazar. OpenRouter'da modeli **sağlayıcı/model** biçiminde yazın.
5. Sarı **parıltı** düğmesine basın. Durum raporu seçtiğiniz sağlayıcıya gönderilir ve yanıt aynı ekranda gösterilir; kopyalayabilir veya .md olarak kaydedebilirsiniz.

Rapor bilgisayar adı, kullanıcı adı ve dosya adı içermez. API kullanımı sağlayıcınız tarafından ücretlendirilebilir.
""", """
In **AI Analysis** (⌘6) choose **Analyze via API**:

1. Click a provider logo: **OpenAI, Claude, Gemini, DeepSeek, GLM (Z.ai)** or **OpenRouter**.
2. The **Get key** icon opens the provider's key page. Create and copy a key.
3. Paste the key and press the **check** icon. It is stored encrypted in the macOS **Keychain**, never in a file. Providers with a saved key show a green key badge.
4. Type the **model name** (e.g. claude-opus-5-5, gpt-5, gemini-2.5-pro, deepseek-chat, glm-4.6). The **magic wand** fills in a suggestion. On OpenRouter use the **provider/model** form.
5. Press the yellow **sparkles** button. The status report is sent to the selected provider and the answer appears on the same screen; copy it or save it as .md.

The report has no computer name, user name or file names. API usage may be billed by your provider.
"""), related: ["ai-rapor", "ai-hatalar"]),
        .init(id: "ai-rapor", category: C.ai, icon: "doc.text.magnifyingglass", title: L("Durum raporunu AI aracınıza verin", "Give the status report to your AI tool"),
              keywords: "durum raporu rapor status report markdown json chatgpt claude gemini yükle upload kopyala copy paylaş share",
              body: L("""
API anahtarınız yoksa **Durum raporu** modunu kullanın:

• **Kopyala ve aç** satırındaki bir logoya tıklayın: rapor panoya kopyalanır ve ChatGPT, Claude, Gemini, DeepSeek, Z.ai Chat veya OpenRouter Chat açılır. Sohbete yapıştırmanız yeterli.
• Ya da raporu **.md** olarak kaydedip dosya olarak yükleyin. Yalnızca sayısal veri isterseniz **{ }** simgesiyle **.json** kaydedin.

Rapor yapay zekâ için düzenlenmiştir: başta hazır bir görev metni, ardından özet, donanım, performans tablosu, en çok kaynak kullanan süreçler, güvenlik denetimi, gereksiz dosyalar, Nabız önerileri ve en sonda makine okunur JSON bulunur. Raporu güncel verilerle yenilemek için **döngü ok** simgesine basın.
""", """
No API key? Use **Status report** mode:

• Click a logo under **Copy & open**: the report is copied to the clipboard and ChatGPT, Claude, Gemini, DeepSeek, Z.ai Chat or OpenRouter Chat opens. Just paste it into the chat.
• Or save the report as **.md** and upload the file. For numbers only, save **.json** with the **{ }** icon.

The report is organized for AI: a ready-made task prompt first, then summary, hardware, a performance table, top processes, the security audit, junk files, Nabız advice and finally machine-readable JSON. Press the **circular arrow** to refresh it with current data.
"""), related: ["ai-api"]),
        .init(id: "ai-hatalar", category: C.ai, icon: "exclamationmark.bubble.fill", title: L("AI analizi hata verdi", "AI analysis failed"),
              keywords: "hata error 401 403 404 429 kota quota bakiye balance model bulunamadı not found anahtar geçersiz invalid key",
              body: L("""
• **HTTP 401 / 403**: Anahtar geçersiz veya yetkisiz. Yeni anahtar yapıştırıp kaydedin.
• **HTTP 404 / 400 model**: Model adı yanlış ya da hesabınızda yok. Sağlayıcının model listesindeki adı birebir yazın.
• **HTTP 402 / 429**: Bakiye veya kota bitti, ya da çok sık istek gönderildi. Biraz bekleyin veya hesabınıza kredi ekleyin.
• **Zaman aşımı**: Büyük modeller birkaç dakika düşünebilir; tekrar deneyin ya da daha hızlı bir model seçin.

Hata mesajı sağlayıcıdan geldiği gibi gösterilir.
""", """
• **HTTP 401 / 403**: The key is invalid or unauthorized. Paste and save a new key.
• **HTTP 404 / 400 model**: The model name is wrong or not available on your account. Type the exact name from the provider's model list.
• **HTTP 402 / 429**: Out of balance or quota, or too many requests. Wait a little or add credit.
• **Timeout**: Large models may think for minutes; retry or pick a faster model.

The error message is shown exactly as the provider returned it.
""")),
        .init(id: "oneriler", category: C.trouble, icon: "lightbulb.max.fill", title: L("Öneriler nasıl oluşturulur?", "How is advice generated?"),
              keywords: "öneri tavsiye kritik uyarı ipucu advice recommendation critical warning tip",
              body: L("""
Nabız ölçümleri ve güvenlik denetimlerini sürekli değerlendirir ve önerileri üç seviyede sıralar:

• **Kritik** (kırmızı): Hemen ilgilenin.
• **Uyarı** (sarı): Yakında ilgilenin.
• **İpucu** (mavi): İsteğe bağlı iyileştirmeler.

Her önerinin yanındaki simge sizi ilgili ayara veya bölüme götürür. Üstteki filtre simgeleriyle listeyi daraltabilirsiniz.
""", """
Nabız continuously evaluates metrics and security checks and ranks advice in three levels:

• **Critical** (red): Deal with it now.
• **Warning** (yellow): Deal with it soon.
• **Tip** (blue): Optional improvements.

The icon next to each item takes you to the related setting or section. Use the filter icons at the top to narrow the list.
""")),
        .init(id: "izin-sorunlari", category: C.trouble, icon: "exclamationmark.bubble.fill", title: L("Bir denetim “okunamadı” diyor", "A check says “could not be read”"),
              keywords: "hata okunamadı çalışmıyor sorun bilinmiyor error not working problem unknown",
              body: L("""
Bazı denetimler macOS sürümüne veya yönetici ayarlarına göre bilgi döndürmeyebilir. Bu durumda kart mavi **bilgi** simgesiyle gösterilir ve puana etki etmez.

Bekleyen güncelleme denetimi internet bağlantısı gerektirir. Kurumsal (MDM) yönetilen Mac'lerde bazı ayarlar BT ekibinizce yönetiliyor olabilir.
""", """
Some checks may return no information depending on the macOS version or administrator settings. The card then shows a blue **info** icon and does not affect the score.

The pending-updates check needs an internet connection. On company-managed (MDM) Macs, some settings may be controlled by your IT team.
""")),
        .init(id: "gizlilik", category: C.trouble, icon: "hand.raised.fill", title: L("Gizlilik", "Privacy"),
              keywords: "gizlilik veri internet gönderme takip privacy data internet send tracking",
              body: L("""
Siz **AI analizi** başlatmadıkça Nabız çevrimdışı çalışır. AI analizinde durum raporu yalnızca seçtiğiniz sağlayıcıya gönderilir; bilgisayar adı, kullanıcı adı ve dosya adı içermez. API anahtarları macOS Anahtar Zinciri'nde saklanır. Diğer tek ağ isteği, macOS'un kendi **softwareupdate** aracının Apple'a güncelleme sormasıdır.
""", """
Nabız works offline unless you start an **AI analysis**. Then the status report goes only to the provider you chose and contains no computer, user or file names. API keys are stored in the macOS Keychain. The only other network request is macOS's own **softwareupdate** tool asking Apple for updates.
""")),
    ] }

    /// Türkçe karakterlere duyarsız, çok kelimeli arama. Başlık eşleşmeleri öne çıkar.
    static func search(_ query: String) -> [HelpTopic] {
        let words = normalize(query).split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard !words.isEmpty else { return topics }
        return topics.compactMap { t -> (HelpTopic, Int)? in
            let title = normalize(t.title), keys = normalize(t.keywords + " " + t.category), body = normalize(t.body)
            var score = 0
            for w in words {
                if title.contains(w) { score += 10 }
                else if keys.contains(w) { score += 5 }
                else if body.contains(w) { score += 1 }
                else { return nil }
            }
            return (t, score)
        }
        .sorted { $0.1 > $1.1 }
        .map(\.0)
    }

    static func normalize(_ s: String) -> String {
        s.replacingOccurrences(of: "ı", with: "i").replacingOccurrences(of: "İ", with: "i")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "tr_TR"))
    }
}
