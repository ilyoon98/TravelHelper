/// Number-to-words conversion for "전체 읽기 모드" (full reading mode).
/// Ported from the HTML prototype's `numberToWordsXX` functions.
///
/// NOTE: approximations only (see spec section 4) — Spanish/Portuguese
/// multiples of 200+ (quinientos, etc.) are simplified and need native-
/// speaker review before release.
library;

class NumberWords {
  final String native;
  final String pronunciation;
  final String korean;

  const NumberWords(this.native, this.pronunciation, this.korean);

  NumberWords operator +(NumberWords other) => NumberWords(
        '$native${other.native}',
        '$pronunciation ${other.pronunciation}',
        '$korean ${other.korean}',
      );

  NumberWords withSpace(NumberWords other) => NumberWords(
        '$native ${other.native}',
        '$pronunciation ${other.pronunciation}',
        '$korean ${other.korean}',
      );
}

/// Languages that support full-sentence reading (all countries map to one
/// of these).
const fullModeLangs = ['en', 'es', 'pt', 'id', 'th', 'ja', 'vi', 'fi', 'ar'];

/// Every numberToWordsXX below only groups "thousands" one level deep (it
/// assumes the value left over after dividing by 1000 is itself under
/// 1000), so anything above 999,999 indexes its digit tables out of range
/// instead of producing a sentence. Supporting 만/million+ needs a real
/// per-language grouping rewrite — tracked as an open item in the spec
/// (section 11: "태국어/일본어/베트남어 만 단위 이상 확장 여부"). Until
/// then, callers should check this bound before calling [numberToWords].
const maxFullReadingValue = 999999;

/// Some scripts write digits differently from the Western 0-9 used for
/// typing on the numpad — Egyptian Arabic normally writes numbers with
/// Arabic-Indic numerals (١٢٣ rather than 123). Returns [digits] rendered in
/// [language]'s native numerals, or null if that language just uses the
/// same 0-9 glyphs (so the caller shows nothing extra).
String? nativeDigitsFor(String language, String digits) {
  final map = _nativeDigitMaps[language];
  if (map == null) return null;
  return digits.split('').map((d) => map[d] ?? d).join();
}

const _nativeDigitMaps = {
  'ar': {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  },
};

NumberWords numberToWords(String language, int n) {
  switch (language) {
    case 'en':
      return _numberToWordsEN(n);
    case 'es':
      return _numberToWordsES(n);
    case 'pt':
      return _numberToWordsPT(n);
    case 'id':
      return _numberToWordsID(n);
    case 'th':
      return _numberToWordsTH(n);
    case 'ja':
      return _numberToWordsJA(n);
    case 'vi':
      return _numberToWordsVI(n);
    case 'fi':
      return _numberToWordsFI(n);
    case 'ar':
      return _numberToWordsAR(n);
    default:
      throw ArgumentError('Unsupported language for full reading mode: $language');
  }
}

/// Adds thousands separators to a plain digit string (no int overflow limit).
String commaFormat(String digits) {
  if (digits.isEmpty) return '0';
  final buffer = StringBuffer();
  final len = digits.length;
  for (var i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

// --------------------------------------------------------------------------
// English
// --------------------------------------------------------------------------
const _enOnes = [
  'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
  'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen',
  'seventeen', 'eighteen', 'nineteen',
];
const _enOnesPhon = [
  'zee-ro', 'wuhn', 'too', 'three', 'for', 'faiv', 'siks', 'sev-uhn', 'eyt', 'nain',
  'ten', 'ee-lev-uhn', 'twelv', 'thur-teen', 'for-teen', 'fif-teen', 'siks-teen',
  'sev-uhn-teen', 'ey-teen', 'nain-teen',
];
const _enOnesKr = [
  '제로', '원', '투', '쓰리', '포', '파이브', '씩스', '세븐', '에잇', '나인',
  '텐', '일레븐', '트웰브', '써틴', '포틴', '피프틴', '씩스틴', '세븐틴', '에이틴', '나인틴',
];
const _enTens = {2: 'twenty', 3: 'thirty', 4: 'forty', 5: 'fifty', 6: 'sixty', 7: 'seventy', 8: 'eighty', 9: 'ninety'};
const _enTensPhon = {2: 'twen-tee', 3: 'thur-tee', 4: 'for-tee', 5: 'fif-tee', 6: 'siks-tee', 7: 'sev-uhn-tee', 8: 'ey-tee', 9: 'nain-tee'};
const _enTensKr = {2: '트웨니', 3: '써티', 4: '포티', 5: '피프티', 6: '씩스티', 7: '세븐티', 8: '에이티', 9: '나인티'};

NumberWords _convertEN(int n) {
  if (n < 20) return NumberWords(_enOnes[n], _enOnesPhon[n], _enOnesKr[n]);
  if (n < 100) {
    final t = n ~/ 10, r = n % 10;
    if (r == 0) return NumberWords(_enTens[t]!, _enTensPhon[t]!, _enTensKr[t]!);
    return NumberWords(
      '${_enTens[t]}-${_enOnes[r]}',
      '${_enTensPhon[t]}-${_enOnesPhon[r]}',
      '${_enTensKr[t]} ${_enOnesKr[r]}',
    );
  }
  final h = n ~/ 100, r = n % 100;
  var result = NumberWords('${_enOnes[h]} hundred', '${_enOnesPhon[h]} hun-druhd', '${_enOnesKr[h]} 헌드레드');
  if (r > 0) result = result.withSpace(_convertEN(r));
  return result;
}

NumberWords _numberToWordsEN(int n) {
  if (n == 0) return const NumberWords('zero', 'zee-ro', '제로');
  if (n < 1000) return _convertEN(n);
  final th = n ~/ 1000, r = n % 1000;
  var result = _convertEN(th).withSpace(const NumberWords('thousand', 'thao-zuhnd', '싸우전드'));
  if (r > 0) result = result.withSpace(_convertEN(r));
  return result;
}

// --------------------------------------------------------------------------
// Spanish
// --------------------------------------------------------------------------
const _esOnes = [
  'cero', 'uno', 'dos', 'tres', 'cuatro', 'cinco', 'seis', 'siete', 'ocho', 'nueve',
  'diez', 'once', 'doce', 'trece', 'catorce', 'quince', 'dieciséis', 'diecisiete',
  'dieciocho', 'diecinueve',
];
const _esOnesPhon = [
  'seh-ro', 'oo-no', 'dos', 'tres', 'kwah-tro', 'seen-ko', 'seys', 'see-eh-teh', 'oh-cho', 'nweh-veh',
  'dee-es', 'on-seh', 'doh-seh', 'treh-seh', 'kah-tor-seh', 'keen-seh', 'dee-es-ee-seys',
  'dee-es-ee-see-eh-teh', 'dee-es-ee-oh-cho', 'dee-es-ee-nweh-veh',
];
const _esOnesKr = [
  '쎄로', '우노', '도스', '뜨레스', '꽈뜨로', '씽꼬', '세이스', '씨에떼', '오초', '누에베',
  '디에스', '온세', '도세', '뜨레세', '까또르세', '낀세', '디에씨세이스', '디에씨씨에떼', '디에씨오초', '디에씨누에베',
];
const _esTens = {2: 'veinte', 3: 'treinta', 4: 'cuarenta', 5: 'cincuenta', 6: 'sesenta', 7: 'setenta', 8: 'ochenta', 9: 'noventa'};
const _esTensPhon = {2: 'veyn-teh', 3: 'treyn-tah', 4: 'kwah-ren-tah', 5: 'seen-kwen-tah', 6: 'seh-sen-tah', 7: 'seh-ten-tah', 8: 'oh-chen-tah', 9: 'noh-ven-tah'};
const _esTensKr = {2: '베인떼', 3: '뜨레인따', 4: '꽈렌따', 5: '씬꾸엔따', 6: '세센따', 7: '세뗀따', 8: '오첸따', 9: '노벤따'};

NumberWords _convertES(int n) {
  if (n < 20) return NumberWords(_esOnes[n], _esOnesPhon[n], _esOnesKr[n]);
  if (n < 100) {
    final t = n ~/ 10, r = n % 10;
    if (r == 0) return NumberWords(_esTens[t]!, _esTensPhon[t]!, _esTensKr[t]!);
    return NumberWords(
      '${_esTens[t]} y ${_esOnes[r]}',
      '${_esTensPhon[t]}-ee-${_esOnesPhon[r]}',
      '${_esTensKr[t]} 이 ${_esOnesKr[r]}',
    );
  }
  if (n == 100) return const NumberWords('cien', 'see-en', '씨엔');
  final h = n ~/ 100, r = n % 100;
  var result = h == 1
      ? const NumberWords('ciento', 'see-en-to', '씨엔또')
      : NumberWords('${_esOnes[h]}cientos', '${_esOnesPhon[h]}-see-en-tos', '${_esOnesKr[h]}시엔또스');
  if (r > 0) result = result.withSpace(_convertES(r));
  return result;
}

NumberWords _numberToWordsES(int n) {
  if (n == 0) return const NumberWords('cero', 'seh-ro', '쎄로');
  if (n < 1000) return _convertES(n);
  final th = n ~/ 1000, r = n % 1000;
  var result = th == 1
      ? const NumberWords('mil', 'meel', '밀')
      : _convertES(th).withSpace(const NumberWords('mil', 'meel', '밀'));
  if (r > 0) result = result.withSpace(_convertES(r));
  return result;
}

// --------------------------------------------------------------------------
// Portuguese
// --------------------------------------------------------------------------
const _ptOnes = [
  'zero', 'um', 'dois', 'três', 'quatro', 'cinco', 'seis', 'sete', 'oito', 'nove',
  'dez', 'onze', 'doze', 'treze', 'quatorze', 'quinze', 'dezesseis', 'dezessete',
  'dezoito', 'dezenove',
];
const _ptOnesPhon = [
  'zeh-ro', 'oom', 'doys', 'tres', 'kwah-tro', 'seen-ko', 'seys', 'seh-chee', 'oy-too', 'no-vee',
  'dez', 'on-zee', 'doh-zee', 'treh-zee', 'kwah-tor-zee', 'keen-zee', 'deh-zee-seys',
  'deh-zee-seh-chee', 'deh-zoy-too', 'deh-zee-no-vee',
];
const _ptOnesKr = [
  '제루', '웅', '도이스', '뜨레스', '꽈뜨루', '씽꾸', '세이스', '세치', '오이뚜', '노비',
  '데스', '옹지', '도지', '뜨레지', '꽈또르지', '낀지', '데지쎄이스', '데지세치', '데조이뚜', '데지노비',
];
const _ptTens = {2: 'vinte', 3: 'trinta', 4: 'quarenta', 5: 'cinquenta', 6: 'sessenta', 7: 'setenta', 8: 'oitenta', 9: 'noventa'};
const _ptTensPhon = {2: 'veen-chee', 3: 'treen-tah', 4: 'kwah-ren-tah', 5: 'seen-kwen-tah', 6: 'seh-sen-tah', 7: 'seh-ten-tah', 8: 'oy-ten-tah', 9: 'noh-ven-tah'};
const _ptTensKr = {2: '빈치', 3: '뜨린따', 4: '꽈렌따', 5: '씽꾸엔따', 6: '쎄센따', 7: '세뗀따', 8: '오이뗀따', 9: '노벤따'};

NumberWords _convertPT(int n) {
  if (n < 20) return NumberWords(_ptOnes[n], _ptOnesPhon[n], _ptOnesKr[n]);
  if (n < 100) {
    final t = n ~/ 10, r = n % 10;
    if (r == 0) return NumberWords(_ptTens[t]!, _ptTensPhon[t]!, _ptTensKr[t]!);
    return NumberWords(
      '${_ptTens[t]} e ${_ptOnes[r]}',
      '${_ptTensPhon[t]}-ee-${_ptOnesPhon[r]}',
      '${_ptTensKr[t]} 이 ${_ptOnesKr[r]}',
    );
  }
  if (n == 100) return const NumberWords('cem', 'seng', '셍');
  final h = n ~/ 100, r = n % 100;
  var result = h == 1
      ? const NumberWords('cento', 'sen-too', '쎈뚜')
      : NumberWords('${_ptOnes[h]}centos', '${_ptOnesPhon[h]}-sen-toos', '${_ptOnesKr[h]}센뚜스');
  if (r > 0) {
    final rem = _convertPT(r);
    result = NumberWords('${result.native} e ${rem.native}', '${result.pronunciation} ee ${rem.pronunciation}', '${result.korean} 이 ${rem.korean}');
  }
  return result;
}

NumberWords _numberToWordsPT(int n) {
  if (n == 0) return const NumberWords('zero', 'zeh-ro', '제루');
  if (n < 1000) return _convertPT(n);
  final th = n ~/ 1000, r = n % 1000;
  var result = th == 1
      ? const NumberWords('mil', 'meew', '미우')
      : _convertPT(th).withSpace(const NumberWords('mil', 'meew', '미우'));
  if (r > 0) {
    final rem = _convertPT(r);
    result = NumberWords('${result.native} e ${rem.native}', '${result.pronunciation} ee ${rem.pronunciation}', '${result.korean} 이 ${rem.korean}');
  }
  return result;
}

// --------------------------------------------------------------------------
// Indonesian
// --------------------------------------------------------------------------
const _idOnes = ['nol', 'satu', 'dua', 'tiga', 'empat', 'lima', 'enam', 'tujuh', 'delapan', 'sembilan'];
const _idOnesPhon = ['nol', 'sah-too', 'doo-ah', 'tee-gah', 'uhm-paht', 'lee-mah', 'uh-nahm', 'too-joo', 'duh-lah-pahn', 'suhm-bee-lahn'];
const _idOnesKr = ['놀', '사뚜', '두아', '띠가', '음빳', '리마', '으남', '뚜주', '들라빤', '슴빌란'];

NumberWords _convertID(int n) {
  if (n == 0) return const NumberWords('nol', 'nol', '놀');
  if (n < 10) return NumberWords(_idOnes[n], _idOnesPhon[n], _idOnesKr[n]);
  if (n == 10) return const NumberWords('sepuluh', 'suh-poo-looh', '스뿌루');
  if (n == 11) return const NumberWords('sebelas', 'suh-buh-lahs', '스블라스');
  if (n < 20) {
    final r = n - 10;
    return NumberWords('${_idOnes[r]} belas', '${_idOnesPhon[r]}-buh-lahs', '${_idOnesKr[r]} 블라스');
  }
  if (n < 100) {
    final t = n ~/ 10, r = n % 10;
    final tens = NumberWords('${_idOnes[t]} puluh', '${_idOnesPhon[t]}-poo-looh', '${_idOnesKr[t]} 뿔루');
    if (r == 0) return tens;
    return NumberWords(
      '${tens.native} ${_idOnes[r]}',
      '${tens.pronunciation} ${_idOnesPhon[r]}',
      '${tens.korean} ${_idOnesKr[r]}',
    );
  }
  final h = n ~/ 100, r = n % 100;
  final hundred = h == 1
      ? const NumberWords('seratus', 'suh-rah-toos', '스라뚜스')
      : NumberWords('${_idOnes[h]} ratus', '${_idOnesPhon[h]}-rah-toos', '${_idOnesKr[h]} 라뚜스');
  if (r == 0) return hundred;
  return hundred.withSpace(_convertID(r));
}

NumberWords _numberToWordsID(int n) {
  if (n == 0) return const NumberWords('nol', 'nol', '놀');
  if (n < 1000) return _convertID(n);
  final th = n ~/ 1000, r = n % 1000;
  var result = th == 1
      ? const NumberWords('seribu', 'suh-ree-boo', '스리부')
      : NumberWords('${_convertID(th).native} ribu', '${_convertID(th).pronunciation}-ree-boo', '${_convertID(th).korean} 리부');
  if (r > 0) result = result.withSpace(_convertID(r));
  return result;
}

// --------------------------------------------------------------------------
// Thai
// --------------------------------------------------------------------------
const _thNativeD = ['ศูนย์', 'หนึ่ง', 'สอง', 'สาม', 'สี่', 'ห้า', 'หก', 'เจ็ด', 'แปด', 'เก้า'];
const _thPhonD = ['soon', 'neung', 'song', 'saam', 'see', 'haa', 'hok', 'jet', 'bpaet', 'gao'];
const _thKrD = ['쑨', '능', '썽', '쌈', '씨', '하', '혹', '쨋', '빠엣', '까오'];

NumberWords _convertTH(int n) {
  if (n < 10) return NumberWords(_thNativeD[n], _thPhonD[n], _thKrD[n]);
  if (n < 100) {
    final t = n ~/ 10, r = n % 10;
    final String tN = t == 1 ? 'สิบ' : (t == 2 ? 'ยี่สิบ' : '${_thNativeD[t]}สิบ');
    final String tP = t == 1 ? 'sip' : (t == 2 ? 'yee sip' : '${_thPhonD[t]} sip');
    final String tK = t == 1 ? '씹' : (t == 2 ? '이씹' : '${_thKrD[t]} 씹');
    if (r == 0) return NumberWords(tN, tP, tK);
    if (r == 1) return NumberWords('$tNเอ็ด', '$tP et', '$tK 엣');
    return NumberWords('$tN${_thNativeD[r]}', '$tP ${_thPhonD[r]}', '$tK ${_thKrD[r]}');
  }
  final h = n ~/ 100, r = n % 100;
  final String hN = h == 1 ? 'ร้อย' : '${_thNativeD[h]}ร้อย';
  final String hP = h == 1 ? 'roi' : '${_thPhonD[h]} roi';
  final String hK = h == 1 ? '로이' : '${_thKrD[h]} 로이';
  if (r == 0) return NumberWords(hN, hP, hK);
  final rem = _convertTH(r);
  return NumberWords('$hN${rem.native}', '$hP ${rem.pronunciation}', '$hK ${rem.korean}');
}

NumberWords _numberToWordsTH(int n) {
  if (n == 0) return NumberWords(_thNativeD[0], _thPhonD[0], _thKrD[0]);
  if (n < 1000) return _convertTH(n);
  final th = n ~/ 1000, r = n % 1000;
  final NumberWords result = th == 1
      ? const NumberWords('พัน', 'phan', '판')
      : NumberWords('${_convertTH(th).native}พัน', '${_convertTH(th).pronunciation} phan', '${_convertTH(th).korean} 판');
  if (r == 0) return result;
  final rem = _convertTH(r);
  return NumberWords('${result.native}${rem.native}', '${result.pronunciation} ${rem.pronunciation}', '${result.korean} ${rem.korean}');
}

// --------------------------------------------------------------------------
// Japanese (hundred/thousand irregular pronunciation tables)
// --------------------------------------------------------------------------
const _jaOnesKanji = ['', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
const _jaOnesPhonC = ['', 'ichi', 'ni', 'san', 'yon', 'go', 'roku', 'nana', 'hachi', 'kyuu'];
const _jaOnesKrC = ['', '이치', '니', '상', '욘', '고', '로쿠', '나나', '하치', '큐'];
const _jaHundred = {
  1: NumberWords('百', 'hyaku', '햐쿠'),
  2: NumberWords('二百', 'nihyaku', '니햐쿠'),
  3: NumberWords('三百', 'sanbyaku', '삼뱌쿠'),
  4: NumberWords('四百', 'yonhyaku', '욘햐쿠'),
  5: NumberWords('五百', 'gohyaku', '고햐쿠'),
  6: NumberWords('六百', 'roppyaku', '롭퍄쿠'),
  7: NumberWords('七百', 'nanahyaku', '나나햐쿠'),
  8: NumberWords('八百', 'happyaku', '핫퍄쿠'),
  9: NumberWords('九百', 'kyuuhyaku', '큐햐쿠'),
};
const _jaThousand = {
  1: NumberWords('千', 'sen', '센'),
  2: NumberWords('二千', 'nisen', '니센'),
  3: NumberWords('三千', 'sanzen', '산젠'),
  4: NumberWords('四千', 'yonsen', '욘센'),
  5: NumberWords('五千', 'gosen', '고센'),
  6: NumberWords('六千', 'rokusen', '로쿠센'),
  7: NumberWords('七千', 'nanasen', '나나센'),
  8: NumberWords('八千', 'hassen', '핫센'),
  9: NumberWords('九千', 'kyuusen', '큐센'),
};

NumberWords _convertJAUnder100(int n) {
  if (n < 10) return NumberWords(_jaOnesKanji[n], _jaOnesPhonC[n], _jaOnesKrC[n]);
  final t = n ~/ 10, r = n % 10;
  final String tN = t == 1 ? '十' : '${_jaOnesKanji[t]}十';
  final String tP = t == 1 ? 'juu' : '${_jaOnesPhonC[t]}juu';
  final String tK = t == 1 ? '쥬' : '${_jaOnesKrC[t]}쥬';
  if (r == 0) return NumberWords(tN, tP, tK);
  return NumberWords('$tN${_jaOnesKanji[r]}', '$tP ${_jaOnesPhonC[r]}', '$tK ${_jaOnesKrC[r]}');
}

NumberWords _convertJAUnder1000(int n) {
  if (n < 100) return _convertJAUnder100(n);
  final h = n ~/ 100, r = n % 100;
  final hun = _jaHundred[h]!;
  if (r == 0) return hun;
  final rem = _convertJAUnder100(r);
  return NumberWords('${hun.native}${rem.native}', '${hun.pronunciation} ${rem.pronunciation}', '${hun.korean} ${rem.korean}');
}

NumberWords _numberToWordsJA(int n) {
  if (n == 0) return const NumberWords('ゼロ', 'zero', '제로');
  if (n < 1000) return _convertJAUnder1000(n);
  final th = n ~/ 1000, r = n % 1000;
  final thou = _jaThousand[th]!;
  if (r == 0) return thou;
  final rem = _convertJAUnder1000(r);
  return NumberWords('${thou.native}${rem.native}', '${thou.pronunciation} ${rem.pronunciation}', '${thou.korean} ${rem.korean}');
}

// --------------------------------------------------------------------------
// Vietnamese (mốt/lăm/linh variants)
// --------------------------------------------------------------------------
const _vnOnesD = ['không', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín'];
const _vnOnesPhonD = ['khohng', 'moht', 'hai', 'ba', 'bohn', 'nam', 'sao', 'bye', 'tam', 'cheen'];
const _vnOnesKrD = ['콩', '못', '하이', '바', '본', '남', '사우', '바이', '땀', '찐'];

NumberWords _convertVI(int n) {
  if (n < 10) return NumberWords(_vnOnesD[n], _vnOnesPhonD[n], _vnOnesKrD[n]);
  if (n == 10) return const NumberWords('mười', 'muh-uh-ee', '므어이');
  if (n < 20) {
    final r = n - 10;
    final String oN = r == 5 ? 'lăm' : _vnOnesD[r];
    final String oP = r == 5 ? 'lam' : _vnOnesPhonD[r];
    final String oK = r == 5 ? '람' : _vnOnesKrD[r];
    return NumberWords('mười $oN', 'muh-uh-ee $oP', '므어이 $oK');
  }
  if (n < 100) {
    final t = n ~/ 10, r = n % 10;
    final String tN = '${_vnOnesD[t]} mươi';
    final String tP = '${_vnOnesPhonD[t]} muh-uh-ee';
    final String tK = '${_vnOnesKrD[t]} 므어이';
    if (r == 0) return NumberWords(tN, tP, tK);
    String oN, oP, oK;
    if (r == 1) {
      oN = 'mốt';
      oP = 'moht';
      oK = '못';
    } else if (r == 5) {
      oN = 'lăm';
      oP = 'lam';
      oK = '람';
    } else {
      oN = _vnOnesD[r];
      oP = _vnOnesPhonD[r];
      oK = _vnOnesKrD[r];
    }
    return NumberWords('$tN $oN', '$tP $oP', '$tK $oK');
  }
  final h = n ~/ 100, r = n % 100;
  final String hN = '${_vnOnesD[h]} trăm';
  final String hP = '${_vnOnesPhonD[h]} cham';
  final String hK = '${_vnOnesKrD[h]} 짬';
  if (r == 0) return NumberWords(hN, hP, hK);
  if (r < 10) {
    return NumberWords('$hN linh ${_vnOnesD[r]}', '$hP leen ${_vnOnesPhonD[r]}', '$hK 린 ${_vnOnesKrD[r]}');
  }
  final rem = _convertVI(r);
  return NumberWords('$hN ${rem.native}', '$hP ${rem.pronunciation}', '$hK ${rem.korean}');
}

NumberWords _numberToWordsVI(int n) {
  if (n == 0) return NumberWords(_vnOnesD[0], _vnOnesPhonD[0], _vnOnesKrD[0]);
  if (n < 1000) return _convertVI(n);
  final th = n ~/ 1000, r = n % 1000;
  var result = _convertVI(th).withSpace(const NumberWords('nghìn', 'ngeen', '응인'));
  if (r > 0) result = result.withSpace(_convertVI(r));
  return result;
}

// --------------------------------------------------------------------------
// Finnish
// --------------------------------------------------------------------------
const _fiOnesD = ['nolla', 'yksi', 'kaksi', 'kolme', 'neljä', 'viisi', 'kuusi', 'seitsemän', 'kahdeksan', 'yhdeksän'];
const _fiOnesPhonD = ['nol-lah', 'ewk-si', 'kahk-si', 'kol-meh', 'nel-yah', 'vee-si', 'koo-si', 'seyt-seh-mahn', 'kahh-dek-sahn', 'ewkh-dek-sahn'];
const _fiOnesKrD = ['놀라', '윅시', '칵시', '꼴메', '넬야', '비시', '꾸시', '세이쩨만', '카흐덱산', '우흐덱산'];

NumberWords _convertFI(int n) {
  if (n < 10) return NumberWords(_fiOnesD[n], _fiOnesPhonD[n], _fiOnesKrD[n]);
  if (n == 10) return const NumberWords('kymmenen', 'kewm-meh-nen', '뀜메넨');
  if (n < 20) {
    final r = n - 10;
    return NumberWords('${_fiOnesD[r]}toista', '${_fiOnesPhonD[r]}-toys-tah', '${_fiOnesKrD[r]} 또이스따');
  }
  if (n < 100) {
    final t = n ~/ 10, r = n % 10;
    final String tN = '${_fiOnesD[t]}kymmentä';
    final String tP = '${_fiOnesPhonD[t]}-kewm-men-tah';
    final String tK = '${_fiOnesKrD[t]} 뀜멘따';
    if (r == 0) return NumberWords(tN, tP, tK);
    return NumberWords('$tN${_fiOnesD[r]}', '$tP-${_fiOnesPhonD[r]}', '$tK ${_fiOnesKrD[r]}');
  }
  if (n == 100) return const NumberWords('sata', 'sah-tah', '사따');
  final h = n ~/ 100, r = n % 100;
  final String hN = h == 1 ? 'sata' : '${_fiOnesD[h]}sataa';
  final String hP = h == 1 ? 'sah-tah' : '${_fiOnesPhonD[h]}-sah-tah';
  final String hK = h == 1 ? '사따' : '${_fiOnesKrD[h]} 사따';
  if (r == 0) return NumberWords(hN, hP, hK);
  final rem = _convertFI(r);
  return NumberWords('$hN${rem.native}', '$hP-${rem.pronunciation}', '$hK ${rem.korean}');
}

// --------------------------------------------------------------------------
// Egyptian Arabic (Masri) — colloquial numbers as actually spoken in Egypt,
// not literary Modern Standard Arabic. Arabic number grammar has gender
// agreement and irregular hundreds/thousands forms that are simplified here
// (same "approximation, needs native review" caveat as Spanish/Portuguese
// above). Ones are said before tens ("خمسة وعشرين" = "five and twenty").
// --------------------------------------------------------------------------
const _arOnesD = ['صفر', 'واحد', 'اتنين', 'تلاتة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'تمانية', 'تسعة'];
const _arOnesPhonD = ['sifr', 'wahid', 'itnein', 'talata', 'arbaa', 'khamsa', 'sitta', 'saba', 'tamanya', 'tisaa'];
const _arOnesKrD = ['시프르', '와히드', '이트네인', '탈라타', '아르바아', '캄사', '시타', '사브아', '타만야', '티스아'];

const _arTeensD = ['عشرة', 'حداشر', 'اتناشر', 'تلتاشر', 'أربعتاشر', 'خمستاشر', 'ستاشر', 'سبعتاشر', 'تمنتاشر', 'تسعتاشر'];
const _arTeensPhonD = ['ashara', 'hidashar', 'itnashar', 'talatashar', 'arbatashar', 'khamastashar', 'sittashar', 'sabatashar', 'tamantashar', 'tisatashar'];
const _arTeensKrD = ['아샤라', '히다샤르', '이트나샤르', '탈라타샤르', '아르바타샤르', '카마스타샤르', '시타샤르', '사바타샤르', '타만타샤르', '티사타샤르'];

const _arTens = {
  2: NumberWords('عشرين', 'ishreen', '이쉬린'),
  3: NumberWords('تلاتين', 'talateen', '탈라틴'),
  4: NumberWords('أربعين', 'arbaeen', '아르바인'),
  5: NumberWords('خمسين', 'khamseen', '캄신'),
  6: NumberWords('ستين', 'sitteen', '시틴'),
  7: NumberWords('سبعين', 'sabeen', '사빈'),
  8: NumberWords('تمانين', 'tamaneen', '타마닌'),
  9: NumberWords('تسعين', 'tiseen', '티신'),
};

const _arHundreds = {
  1: NumberWords('مية', 'miya', '미야'),
  2: NumberWords('ميتين', 'miteen', '미틴'),
  3: NumberWords('تلتمية', 'tultumiya', '툴투미야'),
  4: NumberWords('أربعمية', 'arbaumiya', '아르바우미야'),
  5: NumberWords('خمسمية', 'khumsumiya', '쿰수미야'),
  6: NumberWords('ستمية', 'suttumiya', '수뚜미야'),
  7: NumberWords('سبعمية', 'subumiya', '수부미야'),
  8: NumberWords('تمنمية', 'tumnumiya', '툼누미야'),
  9: NumberWords('تسعمية', 'tusumiya', '투수미야'),
};

NumberWords _convertAR(int n) {
  if (n < 10) return NumberWords(_arOnesD[n], _arOnesPhonD[n], _arOnesKrD[n]);
  if (n < 20) {
    final r = n - 10;
    return NumberWords(_arTeensD[r], _arTeensPhonD[r], _arTeensKrD[r]);
  }
  if (n < 100) {
    final t = n ~/ 10, r = n % 10;
    final tens = _arTens[t]!;
    if (r == 0) return tens;
    final ones = NumberWords(_arOnesD[r], _arOnesPhonD[r], _arOnesKrD[r]);
    return NumberWords(
      '${ones.native} و${tens.native}',
      '${ones.pronunciation} wa ${tens.pronunciation}',
      '${ones.korean} 와 ${tens.korean}',
    );
  }
  final h = n ~/ 100, r = n % 100;
  final hundred = _arHundreds[h]!;
  if (r == 0) return hundred;
  final rem = _convertAR(r);
  return NumberWords(
    '${hundred.native} و${rem.native}',
    '${hundred.pronunciation} wa ${rem.pronunciation}',
    '${hundred.korean} 와 ${rem.korean}',
  );
}

NumberWords _numberToWordsAR(int n) {
  if (n == 0) return NumberWords(_arOnesD[0], _arOnesPhonD[0], _arOnesKrD[0]);
  if (n < 1000) return _convertAR(n);
  final th = n ~/ 1000, r = n % 1000;
  NumberWords thousand;
  if (th == 1) {
    thousand = const NumberWords('ألف', 'alf', '알프');
  } else if (th == 2) {
    thousand = const NumberWords('ألفين', 'alfein', '알페인');
  } else {
    final p = _convertAR(th);
    thousand = NumberWords('${p.native} ألف', '${p.pronunciation} alf', '${p.korean} 알프');
  }
  if (r == 0) return thousand;
  final rem = _convertAR(r);
  return NumberWords(
    '${thousand.native} و${rem.native}',
    '${thousand.pronunciation} wa ${rem.pronunciation}',
    '${thousand.korean} 와 ${rem.korean}',
  );
}

NumberWords _numberToWordsFI(int n) {
  if (n == 0) return NumberWords(_fiOnesD[0], _fiOnesPhonD[0], _fiOnesKrD[0]);
  if (n < 1000) return _convertFI(n);
  final th = n ~/ 1000, r = n % 1000;
  final String native0 = th == 1 ? 'tuhat' : '${_convertFI(th).native}tuhatta';
  final String phon0 = th == 1 ? 'too-haht' : '${_convertFI(th).pronunciation}-too-haht-tah';
  final String kr0 = th == 1 ? '뚜핫' : '${_convertFI(th).korean} 뚜핫따';
  if (r == 0) return NumberWords(native0, phon0, kr0);
  final rem = _convertFI(r);
  return NumberWords('$native0${rem.native}', '$phon0-${rem.pronunciation}', '$kr0 ${rem.korean}');
}
