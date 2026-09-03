import 'package:flutter/widgets.dart';

/// Client-owned copy: labels, empty states and badge names.
///
/// Server-owned strings — error messages, notification titles, subject and
/// group names — are resolved from `_i18n` by `Accept-Language` and are never
/// duplicated here. Translating them twice guarantees the two copies drift.
class S {
  const S(this.lang);

  /// Falls back to Uzbek for any language the app does not carry, which is the
  /// API's own default.
  factory S.of(BuildContext context) => Localizations.of<S>(context, S) ?? const S('uz');

  final String lang;

  static const supported = ['uz', 'ru', 'en'];

  String _t(String key) {
    final table = _tables[lang] ?? _tables['uz']!;
    return table[key] ?? _tables['uz']![key] ?? key;
  }

  // Welcome / auth
  String get welcomeTitle => _t('welcome_title');
  String get welcomeBody => _t('welcome_body');
  String get welcomeCta => _t('welcome_cta');
  String get statStudents => _t('stat_students');
  String get statTests => _t('stat_tests');
  String get statCenters => _t('stat_centers');
  String get rankedOf => _t('ranked_of');
  String get levelSuffix => _t('level_suffix');
  String get roomSuffix => _t('room_suffix');
  String get questionsLabel => _t('questions_label');
  String get timeLimitLabel => _t('time_limit_label');
  String get attemptsLabel => _t('attempts_label');
  String get createTest => _t('create_test');
  String get pickTopic => _t('pick_topic');
  String get pickGroups => _t('pick_groups');
  String get difficulty => _t('difficulty');
  String get difficultyEasy => _t('difficulty_easy');
  String get difficultyMixed => _t('difficulty_mixed');
  String get difficultyHard => _t('difficulty_hard');
  String get mixPrior => _t('mix_prior');
  String get mixPriorHint => _t('mix_prior_hint');
  String get generate => _t('generate');
  String get generating => _t('generating');
  String get generatingHint => _t('generating_hint');
  String get generationFailed => _t('generation_failed');
  String get testReady => _t('test_ready');
  String get quotaLeft => _t('quota_left');
  String get quotaExhausted => _t('quota_exhausted');
  String get noProgram => _t('no_program');
  String get openTest => _t('open_test');
  String get studentsLower => _t('students_lower');
  String get phoneTitle => _t('phone_title');
  String get phoneBody => _t('phone_body');
  String get phoneHint => _t('phone_hint');
  String get phoneHintText => _t('phone_hint_text');
  String get continueLabel => _t('continue');
  String get passwordTitle => _t('password_title');
  String get passwordBody => _t('password_body');
  String get passwordField => _t('password_field');
  String get signIn => _t('sign_in');
  String get loginAdminHint => _t('login_admin_hint');
  String get phoneNotFound => _t('phone_not_found');
  String get phoneNotFoundTitle => _t('phone_not_found_title');
  String get foundStudent => _t('found_student');
  String get foundTeacher => _t('found_teacher');
  String get roleStudent => _t('role_student');
  String get roleTeacher => _t('role_teacher');
  String get foundBody => _t('found_body');
  String get engagementNew => _t('engagement_new');
  String get engagementActive => _t('engagement_active');
  String get engagementSlipping => _t('engagement_slipping');
  String get engagementInactive => _t('engagement_inactive');
  String get successTitle => _t('success_title');
  String get successBody => _t('success_body');
  String get openStepix => _t('open_stepix');
  String get changePasswordTitle => _t('change_password_title');
  String get changePasswordBody => _t('change_password_body');
  String get currentPassword => _t('current_password');
  String get newPassword => _t('new_password');
  String get repeatPassword => _t('repeat_password');
  String get save => _t('save');
  String get passwordsDoNotMatch => _t('passwords_do_not_match');
  String get passwordTooShort => _t('password_too_short');
  String get lockedTitle => _t('locked_title');
  String get backToLogin => _t('back_to_login');

  // Tabs
  String get tabHome => _t('tab_home');
  String get tabTests => _t('tab_tests');
  String get tabRank => _t('tab_rank');
  String get tabGroups => _t('tab_groups');
  String get tabProfile => _t('tab_profile');

  // Student home
  String get greetingMorning => _t('greeting_morning');
  String get greetingDay => _t('greeting_day');
  String get greetingEvening => _t('greeting_evening');
  String get testFromCenter => _t('test_from_center');
  String get start => _t('start');
  String get avgScore => _t('avg_score');
  String get weekActivity => _t('week_activity');
  String get myGroups => _t('my_groups');
  String get noGroupYet => _t('no_group_yet');
  String get noNextTest => _t('no_next_test');
  String get testsTaken => _t('tests_taken');
  String get bestScore => _t('best_score');
  String get place => _t('place');
  String get streak => _t('streak');

  // Tests
  String get tests => _t('tests');
  String get pending => _t('pending');
  String get done => _t('done');
  String get take => _t('take');
  String get continueTest => _t('continue_test');
  String get noPendingTests => _t('no_pending_tests');
  String get noDoneTests => _t('no_done_tests');
  String get questions => _t('questions');
  String get minutes => _t('minutes');
  String get attemptsLeft => _t('attempts_left');
  String get due => _t('due');
  String get passScore => _t('pass_score');
  String get noAttemptsLeft => _t('no_attempts_left');

  // Runner
  String get next => _t('next');
  String get finish => _t('finish');
  String get quitTest => _t('quit_test');
  String get quitTestBody => _t('quit_test_body');
  String get quit => _t('quit');
  String get stay => _t('stay');
  String get timeLeft => _t('time_left');
  String get submitting => _t('submitting');

  // Result
  String get result => _t('result');
  String get passed => _t('passed');
  String get failed => _t('failed');
  String get correctAnswers => _t('correct_answers');
  String get yourAnswer => _t('your_answer');
  String get correctAnswer => _t('correct_answer');
  String get notAnswered => _t('not_answered');
  String get explanation => _t('explanation');
  String get answersHidden => _t('answers_hidden');
  String get newBadges => _t('new_badges');

  // Rank
  String get rating => _t('rating');
  String get yourRank => _t('your_rank');
  String get unranked => _t('unranked');
  String get unrankedNote => _t('unranked_note');
  String get gapToNext => _t('gap_to_next');
  String get emptyBoard => _t('empty_board');
  String get achievements => _t('achievements');

  // Groups
  String get classmates => _t('classmates');
  String get teacher => _t('teacher');
  String get room => _t('room');
  String get schedule => _t('schedule');
  String get groupTests => _t('group_tests');

  // Teacher
  String get teacherBadge => _t('teacher_badge');
  String get needsAttention => _t('needs_attention');
  String get allClear => _t('all_clear');
  String get groupAverages => _t('group_averages');
  String get myGroupTests => _t('my_group_tests');
  String get myGroupTestsNote => _t('my_group_tests_note');
  String get students => _t('students');
  String get register => _t('register');
  String get noTeacherGroups => _t('no_teacher_groups');
  String get noTeacherTests => _t('no_teacher_tests');
  String get open => _t('open');
  String get ok => _t('ok');
  String get progress => _t('progress');
  String get groups => _t('groups');
  String get attendance => _t('attendance');
  String get present => _t('present');
  String get late => _t('late');
  String get absent => _t('absent');
  String get excused => _t('excused');
  String get saveRegister => _t('save_register');
  String get registerSaved => _t('register_saved');
  String get studentNew => _t('student_new');
  String get advice => _t('advice');
  String get adviceNote => _t('advice_note');
  String get strongSkills => _t('strong_skills');
  String get weakSkills => _t('weak_skills');
  String get lastSeen => _t('last_seen');
  String get notStartedTitle => _t('not_started_title');
  String get stateAssigned => _t('state_assigned');
  String get stateInProgress => _t('state_in_progress');
  String get lowScoreTitle => _t('low_score_title');
  String get inactiveTitle => _t('inactive_title');

  // Profile / settings
  String get profile => _t('profile');
  String get settings => _t('settings');
  String get fullName => _t('full_name');
  String get edit => _t('edit');
  String get notifications => _t('notifications');
  String get language => _t('language');
  String get changePassword => _t('change_password');
  String get support => _t('support');
  String get offer => _t('offer');
  String get privacy => _t('privacy');
  String get about => _t('about');
  String get logout => _t('logout');
  String get logoutConfirm => _t('logout_confirm');
  String get cancel => _t('cancel');
  String get noNotifications => _t('no_notifications');
  String get markAllRead => _t('mark_all_read');
  String get version => _t('version');
  String get updateRequired => _t('update_required');
  String get updateRequiredBody => _t('update_required_body');
  String get subscription => _t('subscription');
  String get subscriptionGrace => _t('subscription_grace');
  String get pay => _t('pay');

  // Shared
  String get retry => _t('retry');
  String get offlineTitle => _t('offline_title');
  String get somethingWentWrong => _t('something_went_wrong');
  String get loading => _t('loading');
  String get student => _t('student_role');
  String get teacherRole => _t('teacher_role');

  /// Badge labels live here, not on the server: a badge is a UI object with a
  /// server-side predicate, and shipping its label from the backend adds a
  /// deploy to every wording change.
  String badge(String code) => _t('badge_$code');

  String greeting(String key) => switch (key) {
        'evening' => greetingEvening,
        'day' => greetingDay,
        _ => greetingMorning,
      };

  String weekdayShort(int weekday) => _t('wd_${((weekday - 1) % 7) + 1}');

  static const _tables = <String, Map<String, String>>{
    'uz': {
      'welcome_title': 'Tezroq o\'rgan.\nJiddiyroq o\'yna.',
      'welcome_body': 'AI tuzgan testlar, seriyalar, reyting va har kuni ko\'rinadigan natija.',
      'welcome_cta': 'Raqam bilan kirish',
      'stat_students': 'o\'quvchi',
      'stat_tests': 'test',
      'stat_centers': 'markaz',
      'ranked_of': 'o\'quvchi ichida',
      'level_suffix': 'daraja',
      'room_suffix': 'xona',
      'questions_label': 'Savollar',
      'time_limit_label': 'Vaqt chegarasi',
      'attempts_label': 'Qolgan urinishlar',
      'create_test': 'Test tuzish',
      'pick_topic': 'Mavzu',
      'pick_groups': 'Guruhlar',
      'difficulty': 'Murakkablik',
      'difficulty_easy': 'Oson',
      'difficulty_mixed': 'Aralash',
      'difficulty_hard': 'Qiyin',
      'mix_prior': 'Oldingi mavzular bilan aralashtirish',
      'mix_prior_hint': 'Savollarning uchdan biri shu bo\'limdagi oldin o\'tilgan mavzulardan olinadi.',
      'generate': 'Testni yaratish',
      'generating': 'Test tayyorlanmoqda',
      'generating_hint': 'Bu odatda 10–40 soniya oladi. Ekranni yopsangiz ham to\'xtamaydi.',
      'generation_failed': 'Test yaratilmadi. Qayta urinib ko\'ring.',
      'test_ready': 'Test tayyor',
      'quota_left': 'Bu oyga qolgan',
      'quota_exhausted': 'Bu oyga berilgan limit tugadi. O\'quv markazingizdan oshirishni so\'rang.',
      'no_program': 'Sizga fan biriktirilmagan. O\'quv markazingizga murojaat qiling.',
      'open_test': 'Testni ochish',
      'students_lower': 'o\'quvchi',
      'phone_title': 'Telefon raqamingiz',
      'phone_body': 'O\'quv markazingiz bergan raqamni kiriting.',
      'phone_hint': 'Hisobni o\'quv markaz ochadi',
      'phone_hint_text': 'Ilovada ro\'yxatdan o\'tish yo\'q — raqam va parolni o\'quv markazingiz beradi.',
      'continue': 'Davom etish',
      'password_title': 'Parolni kiriting',
      'password_body': 'Parolni o\'quv markazingiz raqam bilan birga bergan',
      'password_field': 'Parolingiz',
      'sign_in': 'Kirish',
      'login_admin_hint': 'Markaz administratorimisiz? Bu ilova o\'quvchi va o\'qituvchilar uchun — administrator brauzerdagi panelga kiradi.',
      'phone_not_found': 'Bu raqam topilmadi. Raqamni tekshiring yoki o\'quv markazingizga murojaat qiling.',
      'phone_not_found_title': 'Raqam topilmadi',
      'found_student': 'O\'quvchi topildi',
      'found_teacher': 'O\'qituvchi topildi',
      'role_student': 'O\'quvchi',
      'role_teacher': 'O\'qituvchi',
      'found_body': 'Raqam tasdiqlandi. Davom etib parolingizni kiriting.',
      'engagement_new': 'Yangi',
      'engagement_active': 'Faol',
      'engagement_slipping': 'Sustlashdi',
      'engagement_inactive': 'Nofaol',
      'success_title': 'Xush kelibsiz!',
      'success_body': 'Hammasi tayyor. Birinchi testni boshlaymizmi?',
      'open_stepix': 'Stepix\'ni ochish',
      'change_password_title': 'Yangi parol qo\'ying',
      'change_password_body': 'Birinchi kirishda parolni almashtirish shart.',
      'current_password': 'Joriy parol',
      'new_password': 'Yangi parol',
      'repeat_password': 'Yangi parolni takrorlang',
      'save': 'Saqlash',
      'passwords_do_not_match': 'Parollar mos kelmadi',
      'password_too_short': 'Parol kamida 8 ta belgidan iborat bo\'lsin',
      'locked_title': 'Kirish yopiq',
      'back_to_login': 'Kirish sahifasiga',
      'tab_home': 'Asosiy',
      'tab_tests': 'Testlar',
      'tab_rank': 'Reyting',
      'tab_groups': 'Guruhlar',
      'tab_profile': 'Profil',
      'greeting_morning': 'Xayrli tong',
      'greeting_day': 'Xayrli kun',
      'greeting_evening': 'Xayrli kech',
      'test_from_center': 'Markazingiz testi',
      'start': 'Boshlash',
      'avg_score': 'O\'rtacha ball',
      'week_activity': 'Hafta faolligi',
      'my_groups': 'Mening guruhlarim',
      'no_group_yet': 'Sizni hali guruhga qo\'shishmagan. O\'quv markazingizga murojaat qiling.',
      'no_next_test': 'Hozircha yangi test yo\'q',
      'tests_taken': 'test',
      'best_score': 'Eng yaxshi',
      'place': 'O\'rin',
      'streak': 'kun',
      'tests': 'Testlar',
      'pending': 'Kutilmoqda',
      'done': 'Topshirilgan',
      'take': 'Topshirish',
      'continue_test': 'Davom ettirish',
      'no_pending_tests': 'Kutayotgan test yo\'q',
      'no_done_tests': 'Hali test topshirmagansiz',
      'questions': 'savol',
      'minutes': 'daqiqa',
      'attempts_left': 'urinish qoldi',
      'due': 'Muddat',
      'pass_score': 'O\'tish balli',
      'no_attempts_left': 'Urinishlar tugadi',
      'next': 'Keyingi',
      'finish': 'Yakunlash',
      'quit_test': 'Testdan chiqilsinmi?',
      'quit_test_body': 'Belgilangan javoblar saqlanadi, lekin test yakunlanmaydi.',
      'quit': 'Chiqish',
      'stay': 'Davom etish',
      'time_left': 'Qolgan vaqt',
      'submitting': 'Yuborilmoqda…',
      'result': 'Natija',
      'passed': 'O\'tdingiz',
      'failed': 'O\'ta olmadingiz',
      'correct_answers': 'to\'g\'ri javob',
      'your_answer': 'Sizning javobingiz',
      'correct_answer': 'To\'g\'ri javob',
      'not_answered': 'Javob berilmagan',
      'explanation': 'Izoh',
      'answers_hidden': 'Markaz javoblarni ko\'rsatishni o\'chirgan.',
      'new_badges': 'Yangi nishonlar',
      'rating': 'Reyting',
      'your_rank': 'Sizning o\'rningiz',
      'unranked': 'Reytingda emassiz',
      'unranked_note': 'Reytingga kirish uchun kamida 3 ta test topshiring.',
      'gap_to_next': 'Keyingi o\'ringacha',
      'empty_board': 'Markaz o\'quvchilari test topshira boshlaganda reyting paydo bo\'ladi.',
      'achievements': 'Yutuqlar',
      'classmates': 'Guruhdoshlar',
      'teacher': 'O\'qituvchi',
      'room': 'Xona',
      'schedule': 'Dars jadvali',
      'group_tests': 'Guruh testlari',
      'teacher_badge': 'O\'qituvchi',
      'needs_attention': 'E\'tibor talab qiladi',
      'all_clear': 'Hammasi joyida. Bugun e\'tibor talab qiladigan narsa yo\'q.',
      'group_averages': 'Guruhlar o\'rtacha balli',
      'my_group_tests': 'Guruhlarim testlari',
      'my_group_tests_note': 'Nima tayinlangan, kim topshirgan va qanday ball bilan',
      'students': 'O\'quvchilar',
      'register': 'Yo\'qlama',
      'no_teacher_groups': 'Sizga hali guruh biriktirilmagan. Guruhni markaz administratori biriktiradi.',
      'no_teacher_tests': 'Guruhlaringiz uchun hali test tuzilmagan. Testlarni markaz administratori tayyorlaydi.',
      'open': 'Ochish',
      'ok': 'Ok',
      'progress': 'Ballar o\'sishi',
      'groups': 'Guruhlar',
      'attendance': 'Davomat',
      'present': 'Keldi',
      'late': 'Kechikdi',
      'absent': 'Kelmadi',
      'excused': 'Sababli',
      'save_register': 'Yo\'qlamani saqlash',
      'register_saved': 'Yo\'qlama saqlandi',
      'student_new': 'Qo\'shilgan, lekin ilovani hali ochmagan',
      'advice': 'AI tavsiyasi',
      'advice_note': 'Bu baho emas — o\'qituvchi uchun taklif.',
      'strong_skills': 'Kuchli tomonlar',
      'weak_skills': 'Zaif tomonlar',
      'last_seen': 'Oxirgi faollik',
      'not_started_title': 'Testni hech kim boshlamadi',
      'low_score_title': 'Guruh balli past',
      'inactive_title': 'Faol emas',
      'profile': 'Profil',
      'settings': 'Sozlamalar',
      'full_name': 'Ismingiz',
      'edit': 'O\'zgartirish',
      'state_assigned': 'Boshlamagan',
      'state_in_progress': 'Ishlamoqda',
      'notifications': 'Bildirishnomalar',
      'language': 'Til',
      'change_password': 'Parolni o\'zgartirish',
      'support': 'Yordam',
      'offer': 'Ommaviy oferta',
      'privacy': 'Maxfiylik siyosati',
      'about': 'Ilova haqida',
      'logout': 'Hisobdan chiqish',
      'logout_confirm': 'Hisobdan chiqasizmi?',
      'cancel': 'Bekor qilish',
      'no_notifications': 'Bildirishnomalar yo\'q',
      'mark_all_read': 'Hammasini o\'qilgan deb belgilash',
      'version': 'Versiya',
      'update_required': 'Ilovani yangilang',
      'update_required_body': 'Bu versiya endi qo\'llab-quvvatlanmaydi. Davom etish uchun yangi versiyani o\'rnating.',
      'subscription': 'Obuna',
      'subscription_grace': 'To\'lov muddati o\'tdi. Imkoniyatlar hozircha ochiq.',
      'pay': 'To\'lash',
      'retry': 'Qayta urinish',
      'offline_title': 'Ulanish yo\'q',
      'something_went_wrong': 'Xatolik yuz berdi',
      'loading': 'Yuklanmoqda…',
      'student_role': 'O\'quvchi',
      'teacher_role': 'O\'qituvchi',
      'badge_first_test': 'Birinchi test',
      'badge_tests_5': '5 ta test',
      'badge_tests_20': '20 ta test',
      'badge_score_90': '90+ ball',
      'badge_flawless': 'Xatosiz',
      'badge_top3': 'Markaz top-3',
      'wd_1': 'Du',
      'wd_2': 'Se',
      'wd_3': 'Ch',
      'wd_4': 'Pa',
      'wd_5': 'Ju',
      'wd_6': 'Sh',
      'wd_7': 'Ya',
    },
    'ru': {
      'welcome_title': 'Учись быстрее.\nИграй серьёзнее.',
      'welcome_body': 'Тесты от ИИ, серии, рейтинги и прогресс, который видно каждый день.',
      'welcome_cta': 'Войти по номеру',
      'stat_students': 'учеников',
      'stat_tests': 'тестов',
      'stat_centers': 'центров',
      'ranked_of': 'учеников в рейтинге',
      'level_suffix': 'уровень',
      'room_suffix': 'кабинет',
      'questions_label': 'Вопросов',
      'time_limit_label': 'Ограничение времени',
      'attempts_label': 'Осталось попыток',
      'create_test': 'Создать тест',
      'pick_topic': 'Тема',
      'pick_groups': 'Группы',
      'difficulty': 'Сложность',
      'difficulty_easy': 'Лёгкий',
      'difficulty_mixed': 'Смешанный',
      'difficulty_hard': 'Сложный',
      'mix_prior': 'Смешать с пройденными темами',
      'mix_prior_hint': 'Треть вопросов возьмётся из ранее пройденных тем этого раздела.',
      'generate': 'Создать тест',
      'generating': 'Тест готовится',
      'generating_hint': 'Обычно 10–40 секунд. Можно закрыть экран — не остановится.',
      'generation_failed': 'Тест не создан. Попробуйте ещё раз.',
      'test_ready': 'Тест готов',
      'quota_left': 'Осталось в этом месяце',
      'quota_exhausted': 'Лимит на этот месяц исчерпан. Попросите учебный центр увеличить его.',
      'no_program': 'Вам не назначен предмет. Обратитесь в учебный центр.',
      'open_test': 'Открыть тест',
      'students_lower': 'учеников',
      'phone_title': 'Ваш номер телефона',
      'phone_body': 'Введите номер, который выдал ваш учебный центр.',
      'phone_hint': 'Аккаунт создаёт центр',
      'phone_hint_text': 'Регистрации в приложении нет — номер и пароль выдаёт ваш учебный центр.',
      'continue': 'Продолжить',
      'password_title': 'Введите пароль',
      'password_body': 'Пароль выдал ваш учебный центр вместе с номером',
      'password_field': 'Ваш пароль',
      'sign_in': 'Войти',
      'login_admin_hint': 'Вы администратор центра? Это приложение — для учеников и преподавателей; администратор входит в панель в браузере.',
      'phone_not_found': 'Номер не найден. Проверьте номер или обратитесь в учебный центр.',
      'phone_not_found_title': 'Номер не найден',
      'found_student': 'Ученик найден',
      'found_teacher': 'Преподаватель найден',
      'role_student': 'Ученик',
      'role_teacher': 'Преподаватель',
      'found_body': 'Номер подтверждён. Продолжите и введите пароль.',
      'engagement_new': 'Новый',
      'engagement_active': 'Активен',
      'engagement_slipping': 'Слабеет',
      'engagement_inactive': 'Неактивен',
      'success_title': 'Добро пожаловать!',
      'success_body': 'Всё готово. Начнём с первого теста?',
      'open_stepix': 'Открыть Stepix',
      'change_password_title': 'Задайте новый пароль',
      'change_password_body': 'При первом входе пароль нужно сменить.',
      'current_password': 'Текущий пароль',
      'new_password': 'Новый пароль',
      'repeat_password': 'Повторите новый пароль',
      'save': 'Сохранить',
      'passwords_do_not_match': 'Пароли не совпадают',
      'password_too_short': 'Пароль должен быть не короче 8 символов',
      'locked_title': 'Вход закрыт',
      'back_to_login': 'К входу',
      'tab_home': 'Главная',
      'tab_tests': 'Тесты',
      'tab_rank': 'Рейтинг',
      'tab_groups': 'Группы',
      'tab_profile': 'Профиль',
      'greeting_morning': 'Доброе утро',
      'greeting_day': 'Добрый день',
      'greeting_evening': 'Добрый вечер',
      'test_from_center': 'Тест от вашего центра',
      'start': 'Начать',
      'avg_score': 'Средний балл',
      'week_activity': 'Активность недели',
      'my_groups': 'Мои группы',
      'no_group_yet': 'Вас пока не добавили в группу. Обратитесь в свой учебный центр.',
      'no_next_test': 'Новых тестов пока нет',
      'tests_taken': 'тестов',
      'best_score': 'Лучший',
      'place': 'Место',
      'streak': 'дн.',
      'tests': 'Тесты',
      'pending': 'Ждут',
      'done': 'Пройдено',
      'take': 'Пройти',
      'continue_test': 'Продолжить',
      'no_pending_tests': 'Нет тестов, которые вас ждут',
      'no_done_tests': 'Вы ещё не проходили тесты',
      'questions': 'вопросов',
      'minutes': 'минут',
      'attempts_left': 'попыток осталось',
      'due': 'Срок',
      'pass_score': 'Проходной балл',
      'no_attempts_left': 'Попытки закончились',
      'next': 'Далее',
      'finish': 'Завершить',
      'quit_test': 'Выйти из теста?',
      'quit_test_body': 'Отмеченные ответы сохранятся, но тест не будет завершён.',
      'quit': 'Выйти',
      'stay': 'Продолжить',
      'time_left': 'Осталось',
      'submitting': 'Отправляем…',
      'result': 'Результат',
      'passed': 'Пройден',
      'failed': 'Не пройден',
      'correct_answers': 'верных ответов',
      'your_answer': 'Ваш ответ',
      'correct_answer': 'Верный ответ',
      'not_answered': 'Без ответа',
      'explanation': 'Объяснение',
      'answers_hidden': 'Центр отключил показ правильных ответов.',
      'new_badges': 'Новые достижения',
      'rating': 'Рейтинг',
      'your_rank': 'Ваше место',
      'unranked': 'Вы вне рейтинга',
      'unranked_note': 'Чтобы попасть в рейтинг, пройдите хотя бы 3 теста.',
      'gap_to_next': 'До следующего места',
      'empty_board': 'Рейтинг появится, когда ученики центра начнут проходить тесты.',
      'achievements': 'Достижения',
      'classmates': 'Одногруппники',
      'teacher': 'Преподаватель',
      'room': 'Кабинет',
      'schedule': 'Расписание',
      'group_tests': 'Тесты группы',
      'teacher_badge': 'Преподаватель',
      'needs_attention': 'Требует внимания',
      'all_clear': 'Всё в порядке. Сегодня ничего не требует внимания.',
      'group_averages': 'Средний балл групп',
      'my_group_tests': 'Тесты моих групп',
      'my_group_tests_note': 'Что назначено, кто прошёл и с каким баллом',
      'students': 'Ученики',
      'register': 'Журнал',
      'no_teacher_groups': 'Вам пока не назначили группы. Их назначает администратор центра.',
      'no_teacher_tests': 'Для ваших групп ещё не создано тестов. Их собирает администратор центра.',
      'open': 'Открыть',
      'ok': 'Ок',
      'progress': 'Прогресс',
      'groups': 'Группы',
      'attendance': 'Посещаемость',
      'present': 'Был',
      'late': 'Опоздал',
      'absent': 'Не был',
      'excused': 'По уважительной',
      'save_register': 'Сохранить журнал',
      'register_saved': 'Журнал сохранён',
      'student_new': 'Добавлен, но ещё не открывал приложение',
      'advice': 'Совет ИИ',
      'advice_note': 'Это не оценка — подсказка преподавателю.',
      'strong_skills': 'Сильные стороны',
      'weak_skills': 'Слабые стороны',
      'last_seen': 'Последняя активность',
      'not_started_title': 'Тест никто не начал',
      'low_score_title': 'Низкий балл группы',
      'inactive_title': 'Не активен',
      'profile': 'Профиль',
      'settings': 'Настройки',
      'full_name': 'Ваше имя',
      'edit': 'Изменить',
      'state_assigned': 'Не начал',
      'state_in_progress': 'Проходит',
      'notifications': 'Уведомления',
      'language': 'Язык',
      'change_password': 'Сменить пароль',
      'support': 'Поддержка',
      'offer': 'Публичная оферта',
      'privacy': 'Политика конфиденциальности',
      'about': 'О приложении',
      'logout': 'Выйти из аккаунта',
      'logout_confirm': 'Выйти из аккаунта?',
      'cancel': 'Отмена',
      'no_notifications': 'Уведомлений нет',
      'mark_all_read': 'Отметить всё прочитанным',
      'version': 'Версия',
      'update_required': 'Обновите приложение',
      'update_required_body': 'Эта версия больше не поддерживается. Установите новую, чтобы продолжить.',
      'subscription': 'Подписка',
      'subscription_grace': 'Срок оплаты прошёл. Доступ пока открыт.',
      'pay': 'Оплатить',
      'retry': 'Повторить',
      'offline_title': 'Нет соединения',
      'something_went_wrong': 'Что-то пошло не так',
      'loading': 'Загрузка…',
      'student_role': 'Ученик',
      'teacher_role': 'Преподаватель',
      'badge_first_test': 'Первый тест',
      'badge_tests_5': '5 тестов',
      'badge_tests_20': '20 тестов',
      'badge_score_90': '90+ баллов',
      'badge_flawless': 'Без ошибок',
      'badge_top3': 'Топ-3 центра',
      'wd_1': 'Пн',
      'wd_2': 'Вт',
      'wd_3': 'Ср',
      'wd_4': 'Чт',
      'wd_5': 'Пт',
      'wd_6': 'Сб',
      'wd_7': 'Вс',
    },
    'en': {
      'welcome_title': 'Learn faster.\nPlay harder.',
      'welcome_body': 'AI-built tests, streaks, rankings and progress you can see every day.',
      'welcome_cta': 'Sign in with your number',
      'stat_students': 'students',
      'stat_tests': 'tests',
      'stat_centers': 'centers',
      'ranked_of': 'students ranked',
      'level_suffix': 'level',
      'room_suffix': 'room',
      'questions_label': 'Questions',
      'time_limit_label': 'Time limit',
      'attempts_label': 'Attempts left',
      'create_test': 'Create a test',
      'pick_topic': 'Topic',
      'pick_groups': 'Groups',
      'difficulty': 'Difficulty',
      'difficulty_easy': 'Easy',
      'difficulty_mixed': 'Mixed',
      'difficulty_hard': 'Hard',
      'mix_prior': 'Mix with earlier topics',
      'mix_prior_hint': 'A third of the questions come from topics already covered in this branch.',
      'generate': 'Generate the test',
      'generating': 'Building your test',
      'generating_hint': 'Usually 10-40 seconds. It keeps going if you close this screen.',
      'generation_failed': 'The test was not created. Try again.',
      'test_ready': 'Test ready',
      'quota_left': 'Left this month',
      'quota_exhausted': 'You have used this month\'s limit. Ask your learning center to raise it.',
      'no_program': 'You have no subject assigned. Ask your learning center.',
      'open_test': 'Open the test',
      'students_lower': 'students',
      'phone_title': 'Your phone number',
      'phone_body': 'Enter the number your learning center issued.',
      'phone_hint': 'Your center creates the account',
      'phone_hint_text': 'There is no sign-up in the app — your learning center issues the number and the password.',
      'continue': 'Continue',
      'password_title': 'Enter your password',
      'password_body': 'Your learning center issued it together with the number',
      'password_field': 'Your password',
      'sign_in': 'Sign in',
      'login_admin_hint': 'Are you a center admin? This app is for students and teachers — admins sign in to the panel in a browser.',
      'phone_not_found': 'That number was not found. Check it, or ask your learning center.',
      'phone_not_found_title': 'Number not found',
      'found_student': 'Student found',
      'found_teacher': 'Teacher found',
      'role_student': 'Student',
      'role_teacher': 'Teacher',
      'found_body': 'Number confirmed. Continue and enter your password.',
      'engagement_new': 'New',
      'engagement_active': 'Active',
      'engagement_slipping': 'Slipping',
      'engagement_inactive': 'Inactive',
      'success_title': 'Welcome!',
      'success_body': 'You are all set. Shall we start with the first test?',
      'open_stepix': 'Open Stepix',
      'change_password_title': 'Set a new password',
      'change_password_body': 'You must change the password on first sign-in.',
      'current_password': 'Current password',
      'new_password': 'New password',
      'repeat_password': 'Repeat new password',
      'save': 'Save',
      'passwords_do_not_match': 'Passwords do not match',
      'password_too_short': 'Use at least 8 characters',
      'locked_title': 'Access closed',
      'back_to_login': 'Back to sign-in',
      'tab_home': 'Home',
      'tab_tests': 'Tests',
      'tab_rank': 'Rating',
      'tab_groups': 'Groups',
      'tab_profile': 'Profile',
      'greeting_morning': 'Good morning',
      'greeting_day': 'Good afternoon',
      'greeting_evening': 'Good evening',
      'test_from_center': 'Test from your center',
      'start': 'Start',
      'avg_score': 'Average score',
      'week_activity': 'This week',
      'my_groups': 'My groups',
      'no_group_yet': 'Your center has not added you to a group yet.',
      'no_next_test': 'No new tests yet',
      'tests_taken': 'tests',
      'best_score': 'Best',
      'place': 'Rank',
      'streak': 'days',
      'tests': 'Tests',
      'pending': 'Pending',
      'done': 'Completed',
      'take': 'Take',
      'continue_test': 'Continue',
      'no_pending_tests': 'Nothing is waiting for you',
      'no_done_tests': 'You have not taken a test yet',
      'questions': 'questions',
      'minutes': 'minutes',
      'attempts_left': 'attempts left',
      'due': 'Due',
      'pass_score': 'Pass score',
      'no_attempts_left': 'No attempts left',
      'next': 'Next',
      'finish': 'Finish',
      'quit_test': 'Leave the test?',
      'quit_test_body': 'Saved answers are kept, but the test will not be submitted.',
      'quit': 'Leave',
      'stay': 'Stay',
      'time_left': 'Time left',
      'submitting': 'Submitting…',
      'result': 'Result',
      'passed': 'Passed',
      'failed': 'Not passed',
      'correct_answers': 'correct',
      'your_answer': 'Your answer',
      'correct_answer': 'Correct answer',
      'not_answered': 'Not answered',
      'explanation': 'Explanation',
      'answers_hidden': 'Your center turned answer review off.',
      'new_badges': 'New badges',
      'rating': 'Rating',
      'your_rank': 'Your rank',
      'unranked': 'Not ranked yet',
      'unranked_note': 'Take at least 3 tests to enter the ranking.',
      'gap_to_next': 'To the next place',
      'empty_board': 'The ranking appears once students at your center start taking tests.',
      'achievements': 'Achievements',
      'classmates': 'Classmates',
      'teacher': 'Teacher',
      'room': 'Room',
      'schedule': 'Schedule',
      'group_tests': 'Group tests',
      'teacher_badge': 'Teacher',
      'needs_attention': 'Needs attention',
      'all_clear': 'All clear. Nothing needs your attention today.',
      'group_averages': 'Group averages',
      'my_group_tests': 'My groups\' tests',
      'my_group_tests_note': 'What is assigned, who took it and with what score',
      'students': 'Students',
      'register': 'Register',
      'no_teacher_groups': 'No groups assigned yet. Your center admin assigns them.',
      'no_teacher_tests': 'No tests built for your groups yet. Your center admin creates them.',
      'open': 'Open',
      'ok': 'OK',
      'progress': 'Progress',
      'groups': 'Groups',
      'attendance': 'Attendance',
      'present': 'Present',
      'late': 'Late',
      'absent': 'Absent',
      'excused': 'Excused',
      'save_register': 'Save register',
      'register_saved': 'Register saved',
      'student_new': 'Added, but has not opened the app yet',
      'advice': 'AI advice',
      'advice_note': 'A suggestion for the teacher, never a grade.',
      'strong_skills': 'Strong skills',
      'weak_skills': 'Weak skills',
      'last_seen': 'Last seen',
      'not_started_title': 'Nobody started the test',
      'low_score_title': 'Group average is low',
      'inactive_title': 'Inactive',
      'profile': 'Profile',
      'settings': 'Settings',
      'full_name': 'Your name',
      'edit': 'Edit',
      'state_assigned': 'Not started',
      'state_in_progress': 'In progress',
      'notifications': 'Notifications',
      'language': 'Language',
      'change_password': 'Change password',
      'support': 'Support',
      'offer': 'Terms of service',
      'privacy': 'Privacy policy',
      'about': 'About',
      'logout': 'Sign out',
      'logout_confirm': 'Sign out of your account?',
      'cancel': 'Cancel',
      'no_notifications': 'No notifications',
      'mark_all_read': 'Mark all as read',
      'version': 'Version',
      'update_required': 'Update the app',
      'update_required_body': 'This version is no longer supported. Install the new one to continue.',
      'subscription': 'Subscription',
      'subscription_grace': 'Payment is past due. Access stays open for now.',
      'pay': 'Pay',
      'retry': 'Retry',
      'offline_title': 'No connection',
      'something_went_wrong': 'Something went wrong',
      'loading': 'Loading…',
      'student_role': 'Student',
      'teacher_role': 'Teacher',
      'badge_first_test': 'First test',
      'badge_tests_5': '5 tests',
      'badge_tests_20': '20 tests',
      'badge_score_90': '90+ score',
      'badge_flawless': 'Flawless',
      'badge_top3': 'Center top 3',
      'wd_1': 'Mon',
      'wd_2': 'Tue',
      'wd_3': 'Wed',
      'wd_4': 'Thu',
      'wd_5': 'Fri',
      'wd_6': 'Sat',
      'wd_7': 'Sun',
    },
  };
}

/// Installs [S] into the widget tree for the user's language.
class StringsDelegate extends LocalizationsDelegate<S> {
  const StringsDelegate();

  @override
  bool isSupported(Locale locale) => S.supported.contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) async => S(locale.languageCode);

  @override
  bool shouldReload(StringsDelegate old) => false;
}
