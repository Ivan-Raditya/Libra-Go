class Destination {
  final String id;
  final String name;
  final String country;
  final String imageUrl;
  final String description;
  final String bestTime;
  final String estimatedBudget;
  final List<String> tips;

  const Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.imageUrl,
    required this.description,
    required this.bestTime,
    required this.estimatedBudget,
    required this.tips,
  });
}

const List<Destination> popularDestinations = [
  Destination(
    id: '1',
    name: 'Kyoto',
    country: 'JEPANG',
    imageUrl: 'https://picsum.photos/id/1043/800/600',
    description: 'Kyoto adalah pusat kebudayaan tradisional Jepang, terkenal dengan kuil-kuil Buddha klasik, taman, istana kekaisaran, dan distrik geisha tradisional.',
    bestTime: 'Maret - Mei (Musim Semi) & Oktober - November (Musim Gugur)',
    estimatedBudget: 'Rp 15.000.000 - Rp 25.000.000 / minggu',
    tips: [
      'Beli Japan Rail Pass sebelum berangkat untuk hemat biaya transportasi.',
      'Sewa kimono untuk pengalaman berfoto yang lebih otentik.',
      'Gunakan transportasi bus umum menggunakan kartu IC (Suica/Pasmo).',
    ],
  ),
  Destination(
    id: '2',
    name: 'Paris',
    country: 'PERANCIS',
    imageUrl: 'https://picsum.photos/id/1040/800/600',
    description: 'Paris, ibu kota Perancis, adalah kota global yang menjadi pusat seni, mode, keahlian memasak, dan budaya. Pemandangan kotanya yang dipenuhi kafe dan butik sangat ikonik.',
    bestTime: 'April - Juni & September - Oktober',
    estimatedBudget: 'Rp 20.000.000 - Rp 35.000.000 / minggu',
    tips: [
      'Hati-hati dengan copet di tempat wisata utama.',
      'Pelajari beberapa frasa dasar bahasa Perancis seperti "Bonjour" dan "Merci".',
      'Manfaatkan Paris Museum Pass jika Anda berencana mengunjungi banyak museum.',
    ],
  ),
  Destination(
    id: '3',
    name: 'Petra',
    country: 'YORDANIA',
    imageUrl: 'https://picsum.photos/id/1015/800/600',
    description: 'Petra adalah kota kuno yang terkenal dengan arsitektur pahatan batu yang menakjubkan dan sistem saluran airnya. Dikenal juga sebagai "Kota Mawar" karena warna batu tempat ia diukir.',
    bestTime: 'Maret - Mei & September - November',
    estimatedBudget: 'Rp 18.000.000 - Rp 28.000.000 / minggu',
    tips: [
      'Beli Jordan Pass yang sudah mencakup visa dan tiket masuk Petra.',
      'Gunakan sepatu berjalan yang sangat nyaman.',
      'Datanglah pagi-pagi sekali atau sore hari untuk menghindari panas terik dan keramaian.',
    ],
  ),
  Destination(
    id: '4',
    name: 'Ubud',
    country: 'INDONESIA',
    imageUrl: 'https://picsum.photos/id/1018/800/600',
    description: 'Ubud merupakan jantung budaya Bali, dikelilingi oleh hutan hujan, sawah terasering, dan pura-pura Hindu. Tempat yang sempurna untuk retret yoga dan ketenangan.',
    bestTime: 'April - September (Musim Kemarau)',
    estimatedBudget: 'Rp 3.000.000 - Rp 10.000.000 / minggu',
    tips: [
      'Sewa sepeda motor untuk mobilitas yang lebih mudah.',
      'Kunjungi Monkey Forest dengan hati-hati dan jangan bawa makanan terlihat.',
      'Coba kuliner lokal di warung-warung kecil untuk rasa otentik.',
    ],
  ),
  Destination(
    id: '5',
    name: 'Zermatt',
    country: 'SWISS',
    imageUrl: 'https://picsum.photos/id/1036/800/600',
    description: 'Zermatt adalah resor ski terkenal di Pegunungan Alpen Swiss yang terletak di kaki gunung Matterhorn yang ikonik. Kota ini bebas mobil dan menawarkan pemandangan alam yang spektakuler.',
    bestTime: 'Desember - Maret (Ski) & Juli - September (Hiking)',
    estimatedBudget: 'Rp 30.000.000 - Rp 50.000.000 / minggu',
    tips: [
      'Siapkan pakaian tebal meskipun Anda berkunjung di musim panas.',
      'Naik kereta Gornergrat Bahn untuk pemandangan Matterhorn terbaik.',
      'Seluruh kota bebas kendaraan berbahan bakar, jadi bersiaplah untuk banyak berjalan.',
    ],
  ),
  Destination(
    id: '6',
    name: 'New York City',
    country: 'AMERIKA SERIKAT',
    imageUrl: 'https://picsum.photos/id/1022/800/600',
    description: 'New York City menawarkan pengalaman metropolitan tanpa batas dengan gedung pencakar langit, Broadway, museum kelas dunia, dan Central Park yang luas.',
    bestTime: 'April - Juni & September - Awal November',
    estimatedBudget: 'Rp 25.000.000 - Rp 45.000.000 / minggu',
    tips: [
      'Gunakan sistem kereta bawah tanah (Subway) daripada taksi.',
      'Beli CityPass untuk menghemat biaya masuk beberapa atraksi utama.',
      'Berjalan cepat di trotoar agar tidak menghalangi penduduk lokal.',
    ],
  ),
  Destination(
    id: '7',
    name: 'Santorini',
    country: 'YUNANI',
    imageUrl: 'https://images.unsplash.com/photo-1613395877344-13d4a8e0d49e?q=80&w=800&auto=format&fit=crop',
    description: 'Terkenal dengan bangunan bercat putih dengan kubah biru yang menghadap ke Laut Aegea. Destinasi romantis yang sempurna dengan pemandangan matahari terbenam terbaik di dunia.',
    bestTime: 'September - Oktober & April - Mei',
    estimatedBudget: 'Rp 22.000.000 - Rp 40.000.000 / minggu',
    tips: [
      'Pesan akomodasi jauh-jauh hari terutama untuk musim panas.',
      'Kenakan sepatu yang nyaman untuk menaiki banyak anak tangga.',
      'Kunjungi Oia lebih awal untuk mendapatkan spot foto terbaik.'
    ],
  ),
  Destination(
    id: '8',
    name: 'Seoul',
    country: 'KOREA SELATAN',
    imageUrl: 'https://picsum.photos/seed/seoul/800/600',
    description: 'Perpaduan sempurna antara teknologi masa depan dan tradisi kuno. Jelajahi istana bersejarah yang dikelilingi pencakar langit.',
    bestTime: 'April - Juni (Musim Semi) & September - November (Musim Gugur)',
    estimatedBudget: 'Rp 10.000.000 - Rp 20.000.000 / minggu',
    tips: [
      'Gunakan kartu T-Money untuk semua transportasi umum.',
      'Cobalah makanan jalanan di Myeongdong atau Dongdaemun.',
      'Sewa Hanbok untuk masuk gratis ke istana-istana besar.'
    ],
  ),
  Destination(
    id: '9',
    name: 'Sydney',
    country: 'AUSTRALIA',
    imageUrl: 'https://picsum.photos/seed/sydney/800/600',
    description: 'Kota pesisir yang dinamis dengan landmark ikonik seperti Sydney Opera House dan Bondi Beach. Surga bagi pecinta selancar dan hidangan laut.',
    bestTime: 'September - November (Musim Semi) & Maret - Mei (Musim Gugur)',
    estimatedBudget: 'Rp 20.000.000 - Rp 35.000.000 / minggu',
    tips: [
      'Gunakan kartu Opal untuk transportasi yang lebih murah.',
      'Berjalanlah melintasi Sydney Harbour Bridge secara gratis.',
      'Waspadai sinar matahari yang sangat terik, selalu gunakan tabir surya.'
    ],
  ),
  Destination(
    id: '10',
    name: 'Cape Town',
    country: 'AFRIKA SELATAN',
    imageUrl: 'https://picsum.photos/seed/capetown/800/600',
    description: 'Kota di ujung benua Afrika dengan latar belakang Table Mountain yang megah. Kaya akan satwa liar, kebun anggur, dan pantai yang indah.',
    bestTime: 'Maret - Mei & September - November',
    estimatedBudget: 'Rp 15.000.000 - Rp 25.000.000 / minggu',
    tips: [
      'Naik kereta gantung ke puncak Table Mountain saat cuaca cerah.',
      'Kunjungi Boulders Beach untuk melihat penguin Afrika.',
      'Selalu waspada dan hindari berjalan sendirian di malam hari.'
    ],
  ),
  Destination(
    id: '11',
    name: 'London',
    country: 'INGGRIS',
    imageUrl: 'https://picsum.photos/seed/london/800/600',
    description: 'Ibu kota bersejarah dengan landmark terkenal seperti Big Ben, Tower Bridge, dan Buckingham Palace. Pusat budaya, seni, dan sejarah.',
    bestTime: 'Mei - Agustus',
    estimatedBudget: 'Rp 25.000.000 - Rp 45.000.000 / minggu',
    tips: [
      'Gunakan Oyster Card untuk transportasi umum.',
      'Banyak museum kelas dunia yang gratis dikunjungi.',
      'Bawa selalu payung karena cuaca bisa berubah cepat.'
    ],
  ),
  Destination(
    id: '12',
    name: 'Rome',
    country: 'ITALIA',
    imageUrl: 'https://picsum.photos/seed/rome/800/600',
    description: 'Kota abadi dengan reruntuhan kuno seperti Colosseum dan Roman Forum, serta karya seni menakjubkan di Kota Vatikan.',
    bestTime: 'April - Mei & September - Oktober',
    estimatedBudget: 'Rp 20.000.000 - Rp 35.000.000 / minggu',
    tips: [
      'Hati-hati terhadap copet di area wisata padat.',
      'Pesan tiket Colosseum dan Vatikan jauh-jauh hari secara online.',
      'Nikmati gelato asli Italia di kedai lokal (gelateria).'
    ],
  ),
  Destination(
    id: '13',
    name: 'Dubai',
    country: 'UNI EMIRAT ARAB',
    imageUrl: 'https://picsum.photos/seed/dubai/800/600',
    description: 'Kota futuristik di tengah gurun dengan gedung tertinggi di dunia, Burj Khalifa, dan pusat perbelanjaan super mewah.',
    bestTime: 'November - Maret',
    estimatedBudget: 'Rp 15.000.000 - Rp 30.000.000 / minggu',
    tips: [
      'Hormati budaya lokal dengan berpakaian sopan.',
      'Gunakan Metro Dubai untuk menghindari kemacetan dan menghemat biaya.',
      'Kunjungi padang pasir dengan tur safari di sore hari.'
    ],
  ),
  Destination(
    id: '14',
    name: 'Bangkok',
    country: 'THAILAND',
    imageUrl: 'https://picsum.photos/seed/bangkok/800/600',
    description: 'Ibu kota yang ramai dengan kuil-kuil megah, pasar jalanan yang hidup, dan surga kuliner bagi pecinta makanan Asia.',
    bestTime: 'November - Februari',
    estimatedBudget: 'Rp 5.000.000 - Rp 12.000.000 / minggu',
    tips: [
      'Tawar menawar adalah hal wajib saat berbelanja di pasar.',
      'Gunakan BTS Skytrain untuk menghindari kemacetan jalanan.',
      'Berpakaian sopan saat mengunjungi kuil (Wats).'
    ],
  ),
  Destination(
    id: '15',
    name: 'Barcelona',
    country: 'SPANYOL',
    imageUrl: 'https://picsum.photos/seed/barcelona/800/600',
    description: 'Terkenal dengan arsitektur unik karya Antoni Gaudí seperti Sagrada Familia, serta pantai Mediterania yang indah.',
    bestTime: 'Mei - Juni & September - Oktober',
    estimatedBudget: 'Rp 18.000.000 - Rp 30.000.000 / minggu',
    tips: [
      'Selalu waspada terhadap barang bawaan Anda di La Rambla.',
      'Makan malam di Spanyol biasanya dimulai sangat larut (setelah jam 8 malam).',
      'Pesan tiket Sagrada Familia jauh sebelum keberangkatan.'
    ],
  ),
  Destination(
    id: '16',
    name: 'Istanbul',
    country: 'TURKI',
    imageUrl: 'https://picsum.photos/seed/istanbul/800/600',
    description: 'Satu-satunya kota di dunia yang terletak di dua benua (Eropa dan Asia), dengan sejarah perpaduan kekaisaran Bizantium dan Ottoman.',
    bestTime: 'April - Mei & September - Oktober',
    estimatedBudget: 'Rp 10.000.000 - Rp 18.000.000 / minggu',
    tips: [
      'Gunakan Istanbulkart untuk transportasi umum yang lebih murah.',
      'Siapkan kerudung bagi wanita untuk memasuki masjid.',
      'Nikmati secangkir teh Turki (çay) dan Baklava di sore hari.'
    ],
  ),
  Destination(
    id: '17',
    name: 'Rio de Janeiro',
    country: 'BRASIL',
    imageUrl: 'https://picsum.photos/seed/rio/800/600',
    description: 'Dikenal dengan patung Christ the Redeemer, Gunung Sugarloaf, dan pantai ikonik Copacabana serta Ipanema.',
    bestTime: 'Desember - Maret',
    estimatedBudget: 'Rp 15.000.000 - Rp 25.000.000 / minggu',
    tips: [
      'Jangan membawa barang berharga mencolok ke pantai.',
      'Gunakan aplikasi taksi online terpercaya daripada taksi jalanan.',
      'Cobalah pão de queijo (roti keju) khas Brasil.'
    ],
  ),
  Destination(
    id: '18',
    name: 'Amsterdam',
    country: 'BELANDA',
    imageUrl: 'https://picsum.photos/seed/amsterdam/800/600',
    description: 'Kota dengan jaringan kanal abad ke-17 yang indah, rumah sempit yang khas, dan budaya bersepeda yang sangat kuat.',
    bestTime: 'April - Mei (untuk melihat bunga Tulip) & September',
    estimatedBudget: 'Rp 22.000.000 - Rp 35.000.000 / minggu',
    tips: [
      'Sewa sepeda, tapi selalu ikuti aturan lalu lintas sepeda setempat.',
      'Hati-hati jangan berjalan di jalur sepeda.',
      'Pesan tiket Museum Van Gogh dan Anne Frank House jauh-jauh hari.'
    ],
  ),
  Destination(
    id: '19',
    name: 'Machu Picchu',
    country: 'PERU',
    imageUrl: 'https://picsum.photos/seed/machupicchu/800/600',
    description: 'Situs Inka abad ke-15 yang terletak tinggi di pegunungan Andes. Keajaiban arsitektur kuno dengan pemandangan alam yang dramatis.',
    bestTime: 'Mei - Oktober (Musim Kemarau)',
    estimatedBudget: 'Rp 25.000.000 - Rp 40.000.000 / minggu',
    tips: [
      'Aklimatisasi di Cusco selama beberapa hari sebelum mendaki.',
      'Pesan tiket masuk dan kereta api berbulan-bulan sebelumnya.',
      'Bawa lapisan pakaian karena suhu bisa berubah drastis.'
    ],
  ),
  Destination(
    id: '20',
    name: 'Maldives',
    country: 'MALADEWA',
    imageUrl: 'https://picsum.photos/seed/maldives/800/600',
    description: 'Surga tropis di Samudra Hindia, terkenal dengan air sebening kristal, terumbu karang yang kaya, dan resor mewah di atas air.',
    bestTime: 'November - April',
    estimatedBudget: 'Rp 30.000.000 - Rp 80.000.000 / minggu',
    tips: [
      'Pilih menginap di guesthouse di pulau lokal untuk budget yang lebih murah.',
      'Bawa tabir surya yang ramah terumbu karang (reef-safe).',
      'Hormati hukum setempat; alkohol hanya diizinkan di resor pribadi.'
    ],
  ),
];
