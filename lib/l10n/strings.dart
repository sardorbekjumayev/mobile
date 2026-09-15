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
  String get variantMode => _t('variant_mode');
  String get variantSame => _t('variant_same');
  String get variantUnique => _t('variant_unique');
  String get questionTypes => _t('question_types');
  String get questionTypesAutoHint => _t('question_types_auto_hint');
  String get questionTypeSingleChoice => _t('question_type_single_choice');
  String get questionTypeMultipleChoice => _t('question_type_multiple_choice');
  String get questionTypeImageBased => _t('question_type_image_based');
  String get questionTypeDragAndDrop => _t('question_type_drag_and_drop');
  String get dragAndDropHint => _t('drag_and_drop_hint');
  String get dragAndDropPick => _t('drag_and_drop_pick');
  String get multiChoiceHint => _t('multi_choice_hint');
  String get previousQuestion => _t('previous_question');
  String get unansweredTitle => _t('unanswered_title');
  String unansweredBody(int n) => _t('unanswered_body').replaceAll('{n}', '$n');
  String get finishAnyway => _t('finish_anyway');
  String get keepAnswering => _t('keep_answering');
  String get mediaNotAttached => _t('media_not_attached');
  String get attachMedia => _t('attach_media');
  String get correctionUnsupportedType => _t('correction_unsupported_type');
  String get advancedSettings => _t('advanced_settings');
  String get shuffleQuestions => _t('shuffle_questions');
  String get shuffleAnswers => _t('shuffle_answers');
  String get showAnswers => _t('show_answers');
  String get showExplanation => _t('show_explanation');
  String get allowCalculator => _t('allow_calculator');
  String get withImages => _t('with_images');
  String get viewVariants => _t('view_variants');
  String get commonPaper => _t('common_paper');
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
  String get practiceTest => _t('practice_test');
  String get createPracticeTest => _t('create_practice_test');
  String get pickSubject => _t('pick_subject');
  String get addBranch => _t('add_branch');
  String get addTopic => _t('add_topic');
  String get newBranchTitle => _t('new_branch_title');
  String get newTopicTitle => _t('new_topic_title');
  String get nameFieldLabel => _t('name_field_label');
  String get hintFieldLabel => _t('hint_field_label');
  String get downloadPdf => _t('download_pdf');
  String get pdfPreparing => _t('pdf_preparing');
  String get pdfFailed => _t('pdf_failed');
  String get scanAnswers => _t('scan_answers');
  String get sendToStudents => _t('send_to_students');
  String get sendAgain => _t('send_again');
  String get notSentYet => _t('not_sent_yet');
  String get sentToStudents => _t('sent_to_students');
  String get scanUpload => _t('scan_upload');
  String get scanEmpty => _t('scan_empty');
  String get scanReading => _t('scan_reading');
  String get scanMatched => _t('scan_matched');
  String get scanUnmatched => _t('scan_unmatched');
  String get scanFailed => _t('scan_failed');
  String get assignToStudent => _t('assign_to_student');
  String get reviewAnswers => _t('review_answers');
  String get yourAnswerLabel => _t('your_answer_label');
  String get correctAnswerLabel => _t('correct_answer_label');
  String get noAnswer => _t('no_answer');
  String get saveCorrection => _t('save_correction');
  String get scoreUpdated => _t('score_updated');
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

  // AI memory (AI xotira)
  String get knowledgeTitle => _t('knowledge_title');
  String get knowledgeBody => _t('knowledge_body');
  String get knowledgeUploadBody => _t('knowledge_upload_body');
  String get knowledgePrivacy => _t('knowledge_privacy');
  String get knowledgeHomeTitle => _t('knowledge_home_title');
  String get knowledgeHomeBody => _t('knowledge_home_body');
  String get knowledgeNew => _t('knowledge_new');
  String get knowledgeUpload => _t('knowledge_upload');
  String get knowledgeName => _t('knowledge_name');
  String get knowledgeNameHint => _t('knowledge_name_hint');
  String get knowledgeKindTest => _t('knowledge_kind_test');
  String get knowledgeKindWorked => _t('knowledge_kind_worked');
  String get knowledgeKindMaterial => _t('knowledge_kind_material');
  String get knowledgePages => _t('knowledge_pages');
  String get knowledgePagesWord => _t('knowledge_pages_word');
  String get knowledgeQuestionsWord => _t('knowledge_questions_word');
  String get knowledgeLessonsWord => _t('knowledge_lessons_word');
  String get knowledgeNeedPhoto => _t('knowledge_need_photo');
  String get knowledgeNeedName => _t('knowledge_need_name');
  String get knowledgeUploaded => _t('knowledge_uploaded');
  String get knowledgeEmpty => _t('knowledge_empty');
  String get knowledgeStateQueued => _t('knowledge_state_queued');
  String get knowledgeStateAnalyzing => _t('knowledge_state_analyzing');
  String get knowledgeStateDone => _t('knowledge_state_done');
  String get knowledgeStateFailed => _t('knowledge_state_failed');
  String get knowledgeKindExemplar => _t('knowledge_kind_exemplar');
  String get knowledgeKindMisconception => _t('knowledge_kind_misconception');
  String get knowledgeKindPitfall => _t('knowledge_kind_pitfall');
  String get knowledgeKindInsight => _t('knowledge_kind_insight');
  String get knowledgeShared => _t('knowledge_shared');
  String get knowledgePrivate => _t('knowledge_private');
  String get knowledgeDepth => _t('knowledge_depth');
  String get knowledgeDelete => _t('knowledge_delete');
  String get knowledgeDeleteConfirm => _t('knowledge_delete_confirm');
  String get knowledgeCancel => _t('knowledge_cancel');
  String get knowledgeRetry => _t('knowledge_retry');
  String get knowledgeRefresh => _t('knowledge_refresh');
  String get knowledgeAnalyzingNote => _t('knowledge_analyzing_note');

  // My own material, multi-subject teachers, paper tests (titul)
  String get fromMaterial => _t('from_material');
  String get fromMaterialHint => _t('from_material_hint');
  String get materialTitle => _t('material_title');
  String get materialBranch => _t('material_branch');
  String get materialFiles => _t('material_files');
  String get materialPickFile => _t('material_pick_file');
  String get materialLimit => _t('material_limit');
  String get materialUpload => _t('material_upload');
  String get materialReading => _t('material_reading');
  String get materialReady => _t('material_ready');
  String get materialFailed => _t('material_failed');
  String get materialNoText => _t('material_no_text');
  String get materialBadPhoto => _t('material_bad_photo');
  String get materialDerive => _t('material_derive');
  String get materialDeriving => _t('material_deriving');
  String get materialPickTopic => _t('material_pick_topic');
  String get materialNoBranch => _t('material_no_branch');
  String get materialNeedFile => _t('material_need_file');
  String get noGroupsForSubject => _t('no_groups_for_subject');
  String get titulTitle => _t('titul_title');
  String get titulBody => _t('titul_body');
  String get titulDownload => _t('titul_download');
  String get scanHint => _t('scan_hint');
  String get teacherSolutionUpload => _t('teacher_solution_upload');
  String get teacherSolutionBody => _t('teacher_solution_body');

  // Solution sheet (yechim varag'i)
  String get solutionUploadTitle => _t('solution_upload_title');
  String get solutionUploadBody => _t('solution_upload_body');
  String get solutionConventionTitle => _t('solution_convention_title');
  String get solutionConvention1 => _t('solution_convention_1');
  String get solutionConvention2 => _t('solution_convention_2');
  String get solutionConvention3 => _t('solution_convention_3');
  String get solutionRetryNotice => _t('solution_retry_notice');
  String get solutionCamera => _t('solution_camera');
  String get solutionGallery => _t('solution_gallery');
  String get solutionPagesLabel => _t('solution_pages_label');
  String get solutionUploadAndSubmit => _t('solution_upload_and_submit');
  String get solutionUpload => _t('solution_upload');
  String get solutionUploaded => _t('solution_uploaded');
  String get solutionNeedOne => _t('solution_need_one');
  String get solutionPendingTitle => _t('solution_pending_title');
  String get solutionPendingRetry => _t('solution_pending_retry');
  String get solutionAnalysis => _t('solution_analysis');
  String get solutionRefresh => _t('solution_refresh');
  String get solutionRefreshHint => _t('solution_refresh_hint');
  String get solutionMethod => _t('solution_method');
  String get solutionStrengths => _t('solution_strengths');
  String get solutionWeaknesses => _t('solution_weaknesses');
  String get solutionRecommendations => _t('solution_recommendations');
  String get solutionLegibility => _t('solution_legibility');
  String get solutionErrors => _t('solution_errors');
  String get solutionGuessed => _t('solution_guessed');
  String get solutionNoWork => _t('solution_no_work');
  String get solutionQuestions => _t('solution_questions');
  String get solutionQuestionSuffix => _t('solution_question_suffix');
  String get solutionRequiredToggle => _t('solution_required_toggle');
  String get solutionRequiredHint => _t('solution_required_hint');
  String get solutionSamplePdf => _t('solution_sample_pdf');
  String get solutionRequiredNote => _t('solution_required_note');
  String get guessSuspected => _t('guess_suspected');

  /// `waiting` · `analyzing` · `done` · `failed`, or null for "not uploaded".
  String solutionStateLabel(String? wire) => _t('solution_state_${wire ?? 'none'}');

  /// `calculation` · `formula` · … · `none`.
  String solutionErrorType(String wire) => _t('solution_error_$wire');

  /// `full` · `partial` · `none`.
  String solutionWork(String wire) => _t('solution_work_$wire');

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
  String get openAction => _t('open_action');
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
      'variant_mode': 'Variant turi',
      'variant_same': 'Hammaga bir xil',
      'variant_unique': 'Individual',
      'question_types': 'Savol turlari',
      'question_types_auto_hint':
          'Tanlanmasa, sun\'iy intellekt hozircha faqat bitta to\'g\'ri javobli savollar tuzadi.',
      'question_type_single_choice': 'Bitta to\'g\'ri javob',
      'question_type_multiple_choice': 'Bir nechta to\'g\'ri javob',
      'question_type_image_based': 'Rasmli',
      'question_type_drag_and_drop': 'Moslashtirish',
      'drag_and_drop_hint': 'Har bir raqamga mos harfni tanlang.',
      'drag_and_drop_pick': 'Tanlang',
      'multi_choice_hint': "Bir nechta to'g'ri javobni belgilashingiz mumkin",
      'previous_question': 'Oldingi',
      'unanswered_title': 'Hamma savolga javob berilmagan',
      'unanswered_body': '{n} ta savol javobsiz qoldi. Javobsiz savollar noto\'g\'ri hisoblanadi.',
      'finish_anyway': 'Baribir yakunlash',
      'keep_answering': 'Qaytish',
      'media_not_attached': 'Fayl biriktirilmagan',
      'attach_media': 'Fayl biriktirish',
      'correction_unsupported_type':
          'Bu turdagi savol uchun tuzatish hozircha qo\'llab-quvvatlanmaydi — web panelda tahrirlang.',
      'advanced_settings': 'Qo\'shimcha sozlamalar',
      'shuffle_questions': 'Savollar tartibini aralashtirish',
      'shuffle_answers': 'Javoblar tartibini aralashtirish',
      'show_answers': 'Topshirgach to\'g\'ri javobni ko\'rsatish',
      'show_explanation': 'Tushuntirish bilan ko\'rsatish',
      'allow_calculator': 'Kalkulyatorga ruxsat berish',
      'with_images': 'Rasmli savollar (AI chizadi)',
      'view_variants': 'Variantlarni ko\'rish',
      'common_paper': 'Umumiy variant',
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
      'practice_test': 'Mashq testi',
      'create_practice_test': 'Mashq testi yaratish',
      'pick_subject': 'Fan',
      'add_branch': '+ Yangi bo\'lim',
      'add_topic': '+ Yangi mavzu',
      'new_branch_title': 'Yangi bo\'lim',
      'new_topic_title': 'Yangi mavzu',
      'name_field_label': 'Nomi',
      'hint_field_label': 'Izoh (ixtiyoriy)',
      'download_pdf': 'PDF yuklab olish',
      'pdf_preparing': 'PDF tayyorlanmoqda...',
      'pdf_failed': 'PDF olishda xatolik yuz berdi.',
      'scan_answers': 'Qog\'oz javoblarini skanerlash',
      'send_to_students': 'O\'quvchilarga yuborish',
      'send_again': 'Qayta yuborish',
      'not_sent_yet': 'Test hali yuborilmagan — o\'quvchilar uni ko\'rmaydi',
      'sent_to_students': 'Yuborildi',
      'scan_upload': 'Suratlarni tanlash',
      'scan_empty': 'Hali skan qilingan varaq yo\'q.',
      'scan_reading': 'O\'qilmoqda',
      'scan_matched': 'Baholandi',
      'scan_unmatched': 'O\'quvchi topilmadi',
      'scan_failed': 'O\'qib bo\'lmadi',
      'assign_to_student': 'O\'quvchini biriktirish',
      'review_answers': 'Javoblarni ko\'rish',
      'your_answer_label': 'Tanlagan javobi',
      'correct_answer_label': 'To\'g\'ri javob',
      'no_answer': 'Javob berilmagan',
      'save_correction': 'To\'g\'irlashni saqlash',
      'score_updated': 'Ball yangilandi',
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
      'open_action': 'Ochish',
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
      'knowledge_title': 'AI xotira',
      'knowledge_body': 'O\'zingiz tuzgan testlarni yoki o\'quvchilar ishlagan varaqlarni rasmga olib yuklang. AI savollar va xatolardan o\'rganadi — keyingi testlar chuqurroq bo\'ladi.',
      'knowledge_upload_body': 'Har bir sahifani yorug\' joyda, tekis holatda suratga oling. AI savollarni, to\'g\'ri javoblarni va o\'quvchi xatolarini o\'qib oladi.',
      'knowledge_privacy': 'Savollaringiz faqat markazingiz testlariga namuna bo\'ladi. Boshqa markazlarga savol matni emas, faqat umumiy xulosalar (tipik xatolar) ulashiladi.',
      'knowledge_home_title': 'AI xotiraga yuklang',
      'knowledge_home_body': 'Testlaringiz va ishlangan varaqlardan AI o\'rganadi',
      'knowledge_new': 'Yangi yuklash',
      'knowledge_upload': 'Yuklash va tahlil qilish',
      'knowledge_name': 'Nomi',
      'knowledge_name_hint': 'Masalan: 9-sinf algebra nazorat ishi',
      'knowledge_kind_test': 'Test',
      'knowledge_kind_worked': 'Ishlangan varaq',
      'knowledge_kind_material': 'Material',
      'knowledge_pages': 'Sahifalar',
      'knowledge_pages_word': 'sahifa',
      'knowledge_questions_word': 'savol',
      'knowledge_lessons_word': 'xulosa',
      'knowledge_need_photo': 'Kamida bitta rasm qo\'shing',
      'knowledge_need_name': 'Nomini yozing',
      'knowledge_uploaded': 'Yuklandi — AI tahlil qilyapti',
      'knowledge_empty': 'Hali hech narsa yuklanmagan. Birinchi testingizni suratga olib yuklang.',
      'knowledge_state_queued': 'Navbatda',
      'knowledge_state_analyzing': 'Tahlil qilinmoqda',
      'knowledge_state_done': 'Tayyor',
      'knowledge_state_failed': 'Xato',
      'knowledge_kind_exemplar': 'Namuna savol',
      'knowledge_kind_misconception': 'Tipik xato',
      'knowledge_kind_pitfall': 'Sayozlik',
      'knowledge_kind_insight': 'Xulosa',
      'knowledge_shared': 'Hammaga ulashiladi',
      'knowledge_private': 'Faqat markazingiz',
      'knowledge_depth': 'chuqurlik',
      'knowledge_delete': 'O\'chirish',
      'knowledge_delete_confirm': 'Yuklama va undan olingan xulosalar xotiradan o\'chiriladi. Davom etasizmi?',
      'knowledge_cancel': 'Bekor qilish',
      'knowledge_retry': 'Qayta tahlil qilish',
      'knowledge_refresh': 'Yangilash',
      'knowledge_analyzing_note': 'Bir-besh daqiqa ketadi. Sahifani yopib qo\'yishingiz mumkin.',
      'solution_upload_title': 'Ishlangan varag\'ingizni yuklang',
      'solution_upload_body':
          'O\'qituvchingiz yechimlar yozilgan varaqni so\'ragan. Har bir sahifani aniq rasmga oling — sun\'iy intellekt ishlash usulingizni tahlil qiladi. Rasmlar tahlildan so\'ng o\'chiriladi.',
      'solution_convention_title': 'Varaq qanday to\'ldiriladi',
      'solution_convention_1': 'Hoshiyaga savol raqamini yozing: 1',
      'solution_convention_2': 'Savolni yechib, ostiga gorizontal chiziq torting',
      'solution_convention_3': 'Keyin 2, 3 va hokazo — xuddi shunday davom eting',
      'solution_retry_notice': 'Oldingi varaqni o\'qib bo\'lmadi. Yorug\'roq joyda, aniqroq rasmga olib qayta yuklang.',
      'solution_camera': 'Kamera',
      'solution_gallery': 'Galereya',
      'solution_pages_label': 'Sahifalar',
      'solution_upload_and_submit': 'Yuklash va topshirish',
      'solution_upload': 'Yuklash',
      'solution_uploaded': 'Varaq yuklandi',
      'solution_need_one': 'Kamida bitta sahifa rasmini qo\'shing.',
      'solution_pending_title': 'Ishlangan varaqni yuklang',
      'solution_pending_retry': 'Varaq o\'qilmadi — qayta yuklang',
      'solution_analysis': 'Yechim tahlili',
      'solution_refresh': 'Yangilash',
      'solution_refresh_hint': 'Tahlil odatda bir necha daqiqa oladi.',
      'solution_method': 'Ishlash uslubi',
      'solution_strengths': 'Kuchli tomonlar',
      'solution_weaknesses': 'Zaif tomonlar',
      'solution_recommendations': 'Tavsiyalar',
      'solution_legibility': 'Yozuv o\'qilishi',
      'solution_errors': 'Xatolar',
      'solution_guessed': 'Taxmin',
      'solution_no_work': 'Yechimsiz',
      'solution_questions': 'Savollar bo\'yicha',
      'solution_question_suffix': 'savol',
      'solution_required_toggle': 'Yechim varag\'ini talab qilish',
      'solution_required_hint':
          'O\'quvchi test oxirida ishlangan varag\'ini rasmga olib yuklaydi; AI yechim usulini tahlil qiladi.',
      'solution_sample_pdf': 'Namuna varaq (PDF)',
      'solution_required_note': 'Ishlangan varaq talab qilinadi',
      'guess_suspected': 'Taxmin qilingan bo\'lishi mumkin',
      'solution_state_waiting': 'Tahlilni kutmoqda',
      'solution_state_analyzing': 'Tahlil qilinmoqda',
      'solution_state_done': 'Tahlil tayyor',
      'solution_state_failed': 'O\'qib bo\'lmadi — qayta yuklang',
      'solution_state_none': 'Yuklanmagan',
      'solution_error_calculation': 'Hisoblash xatosi',
      'solution_error_formula': 'Formula xatosi',
      'solution_error_concept': 'Tushuncha xatosi',
      'solution_error_units': 'Birlik xatosi',
      'solution_error_misread': 'Savolni noto\'g\'ri tushungan',
      'solution_error_incomplete': 'Oxiriga yetkazmagan',
      'solution_error_no_work': 'Yechim yozilmagan',
      'solution_error_none': 'Xatosiz',
      'solution_work_full': 'To\'liq yechim',
      'solution_work_partial': 'Qisman',
      'solution_work_none': 'Yechim yo\'q',
      'wd_7': 'Ya',
      'from_material': 'O\'z materialimdan',
      'from_material_hint':
          'Konspekt, qo\'llanma sahifasi yoki PDF/DOCX yuklang — AI undan mavzu ajratib, savollarni aynan shu materialdan tuzadi.',
      'material_title': 'O\'z materialim',
      'material_branch': 'Bo\'lim',
      'material_files': 'Fayllar',
      'material_pick_file': 'PDF / DOCX',
      'material_limit': 'Bir martada 6 tagacha fayl, har biri 8 MB gacha.',
      'material_upload': 'Yuklash va o\'qish',
      'material_reading': 'O\'qilmoqda…',
      'material_ready': 'O\'qildi',
      'material_failed': 'Matn ajratilmadi',
      'material_no_text': 'Bu PDF da matn qatlami yo\'q — bu skan. Rasm sifatida yuklang.',
      'material_bad_photo': 'Rasmni o\'qib bo\'lmadi — aniqroq rasm yuklang.',
      'material_derive': 'Mavzularni aniqlash',
      'material_deriving': 'AI mavzularni ajratyapti…',
      'material_pick_topic': 'Test uchun mavzuni tanlang',
      'material_no_branch': 'Avval bo\'lim qo\'shing — mavzular bo\'lim ichiga qo\'shiladi.',
      'material_need_file': 'Kamida bitta fayl yoki rasm qo\'shing',
      'no_groups_for_subject': 'Bu fan bo\'yicha guruhingiz yo\'q.',
      'titul_title': 'Qog\'oz test va titul',
      'titul_body':
          'PDF da har bir o\'quvchi uchun savollar va oxirgi sahifada titul (javob varag\'i) bor. Chop eting, o\'quvchilar to\'ldirgach titullarni skanerlang.',
      'titul_download': 'PDF va titulni yuklab olish',
      'scan_hint':
          'To\'ldirilgan titullarni suratga oling — AI o\'qib, har bir o\'quvchini avtomatik baholaydi.',
      'teacher_solution_upload': 'Yechim varag\'ini yuklash',
      'teacher_solution_body':
          'O\'quvchi qog\'ozda ishlagan yechim varag\'ini suratga oling — AI ishlash usulini tahlil qiladi va natija o\'quvchi profiliga qo\'shiladi.',
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
      'variant_mode': 'Тип варианта',
      'variant_same': 'Одинаковый для всех',
      'variant_unique': 'Индивидуальный',
      'question_types': 'Типы вопросов',
      'question_types_auto_hint':
          'Если не выбрано, ИИ пока составляет только вопросы с одним правильным ответом.',
      'question_type_single_choice': 'Один правильный ответ',
      'question_type_multiple_choice': 'Несколько правильных ответов',
      'question_type_image_based': 'С изображением',
      'question_type_drag_and_drop': 'Сопоставление',
      'drag_and_drop_hint': 'Выберите подходящую букву для каждого номера.',
      'drag_and_drop_pick': 'Выбрать',
      'multi_choice_hint': 'Можно отметить несколько правильных ответов',
      'previous_question': 'Назад',
      'unanswered_title': 'Ответы даны не на все вопросы',
      'unanswered_body': 'Без ответа: {n}. Вопросы без ответа считаются неверными.',
      'finish_anyway': 'Всё равно завершить',
      'keep_answering': 'Вернуться',
      'media_not_attached': 'Файл не прикреплён',
      'attach_media': 'Прикрепить файл',
      'correction_unsupported_type':
          'Исправление для этого типа вопроса пока не поддерживается — редактируйте в веб-панели.',
      'advanced_settings': 'Дополнительные настройки',
      'shuffle_questions': 'Перемешать порядок вопросов',
      'shuffle_answers': 'Перемешать порядок ответов',
      'show_answers': 'Показать правильный ответ после сдачи',
      'show_explanation': 'Показывать с объяснением',
      'allow_calculator': 'Разрешить калькулятор',
      'with_images': 'Вопросы с картинками (рисует ИИ)',
      'view_variants': 'Посмотреть варианты',
      'common_paper': 'Общий вариант',
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
      'practice_test': 'Тренировочный тест',
      'create_practice_test': 'Создать тренировочный тест',
      'pick_subject': 'Предмет',
      'add_branch': '+ Новый раздел',
      'add_topic': '+ Новая тема',
      'new_branch_title': 'Новый раздел',
      'new_topic_title': 'Новая тема',
      'name_field_label': 'Название',
      'hint_field_label': 'Описание (необязательно)',
      'download_pdf': 'Скачать PDF',
      'pdf_preparing': 'PDF готовится...',
      'pdf_failed': 'Не удалось получить PDF.',
      'scan_answers': 'Сканировать бумажные ответы',
      'send_to_students': 'Отправить ученикам',
      'send_again': 'Отправить повторно',
      'not_sent_yet': 'Тест ещё не отправлен — ученики его не видят',
      'sent_to_students': 'Отправлено',
      'scan_upload': 'Выбрать фото',
      'scan_empty': 'Пока нет отсканированных листов.',
      'scan_reading': 'Читается',
      'scan_matched': 'Оценено',
      'scan_unmatched': 'Ученик не найден',
      'scan_failed': 'Не удалось прочитать',
      'assign_to_student': 'Прикрепить к ученику',
      'review_answers': 'Посмотреть ответы',
      'your_answer_label': 'Выбранный ответ',
      'correct_answer_label': 'Правильный ответ',
      'no_answer': 'Нет ответа',
      'save_correction': 'Сохранить исправление',
      'score_updated': 'Балл обновлён',
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
      'open_action': 'Открыть',
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
      'knowledge_title': 'ИИ-память',
      'knowledge_body': 'Загрузите фото своих тестов или листов, решённых учениками. ИИ учится на вопросах и ошибках — следующие тесты станут глубже.',
      'knowledge_upload_body': 'Снимайте каждую страницу ровно и при хорошем свете. ИИ прочитает вопросы, ответы и ошибки учеников.',
      'knowledge_privacy': 'Ваши вопросы служат образцом только для тестов вашего центра. Другим центрам передаются лишь общие выводы (типичные ошибки), не текст вопросов.',
      'knowledge_home_title': 'Загрузить в ИИ-память',
      'knowledge_home_body': 'ИИ учится на ваших тестах и решённых листах',
      'knowledge_new': 'Новая загрузка',
      'knowledge_upload': 'Загрузить и разобрать',
      'knowledge_name': 'Название',
      'knowledge_name_hint': 'Например: контрольная по алгебре, 9 класс',
      'knowledge_kind_test': 'Тест',
      'knowledge_kind_worked': 'Решённые листы',
      'knowledge_kind_material': 'Материал',
      'knowledge_pages': 'Страницы',
      'knowledge_pages_word': 'стр.',
      'knowledge_questions_word': 'вопр.',
      'knowledge_lessons_word': 'выводов',
      'knowledge_need_photo': 'Добавьте хотя бы одно фото',
      'knowledge_need_name': 'Укажите название',
      'knowledge_uploaded': 'Загружено — ИИ разбирает',
      'knowledge_empty': 'Пока ничего не загружено. Сфотографируйте свой первый тест.',
      'knowledge_state_queued': 'В очереди',
      'knowledge_state_analyzing': 'Разбирается',
      'knowledge_state_done': 'Готово',
      'knowledge_state_failed': 'Ошибка',
      'knowledge_kind_exemplar': 'Образец вопроса',
      'knowledge_kind_misconception': 'Типичная ошибка',
      'knowledge_kind_pitfall': 'Поверхностность',
      'knowledge_kind_insight': 'Вывод',
      'knowledge_shared': 'Доступно всем центрам',
      'knowledge_private': 'Только ваш центр',
      'knowledge_depth': 'глубина',
      'knowledge_delete': 'Удалить',
      'knowledge_delete_confirm': 'Загрузка и полученные из неё выводы будут удалены. Продолжить?',
      'knowledge_cancel': 'Отмена',
      'knowledge_retry': 'Разобрать заново',
      'knowledge_refresh': 'Обновить',
      'knowledge_analyzing_note': 'Займёт одну-пять минут. Экран можно закрыть.',
      'solution_upload_title': 'Загрузите лист с решениями',
      'solution_upload_body':
          'Учитель попросил лист с вашими решениями. Сфотографируйте каждую страницу чётко — ИИ разберёт ваш способ решения. Фото удаляются после анализа.',
      'solution_convention_title': 'Как заполнять лист',
      'solution_convention_1': 'На полях напишите номер вопроса: 1',
      'solution_convention_2': 'Решите и проведите под решением горизонтальную линию',
      'solution_convention_3': 'Дальше 2, 3 и так далее — точно так же',
      'solution_retry_notice': 'Прошлый лист не удалось прочитать. Сфотографируйте при хорошем свете и загрузите снова.',
      'solution_camera': 'Камера',
      'solution_gallery': 'Галерея',
      'solution_pages_label': 'Страницы',
      'solution_upload_and_submit': 'Загрузить и сдать',
      'solution_upload': 'Загрузить',
      'solution_uploaded': 'Лист загружен',
      'solution_need_one': 'Добавьте фото хотя бы одной страницы.',
      'solution_pending_title': 'Загрузите лист с решениями',
      'solution_pending_retry': 'Лист не прочитан — загрузите снова',
      'solution_analysis': 'Разбор решений',
      'solution_refresh': 'Обновить',
      'solution_refresh_hint': 'Анализ обычно занимает несколько минут.',
      'solution_method': 'Способ решения',
      'solution_strengths': 'Сильные стороны',
      'solution_weaknesses': 'Слабые стороны',
      'solution_recommendations': 'Рекомендации',
      'solution_legibility': 'Разборчивость',
      'solution_errors': 'Ошибки',
      'solution_guessed': 'Угадано',
      'solution_no_work': 'Без решения',
      'solution_questions': 'По вопросам',
      'solution_question_suffix': 'вопрос',
      'solution_required_toggle': 'Требовать лист с решениями',
      'solution_required_hint':
          'В конце теста ученик фотографирует лист с решениями; ИИ разбирает способ решения.',
      'solution_sample_pdf': 'Образец листа (PDF)',
      'solution_required_note': 'Требуется лист с решениями',
      'guess_suspected': 'Возможно, угадано',
      'solution_state_waiting': 'Ожидает анализа',
      'solution_state_analyzing': 'Анализируется',
      'solution_state_done': 'Анализ готов',
      'solution_state_failed': 'Не удалось прочитать — загрузите снова',
      'solution_state_none': 'Не загружен',
      'solution_error_calculation': 'Ошибка в вычислениях',
      'solution_error_formula': 'Ошибка в формуле',
      'solution_error_concept': 'Ошибка в понимании',
      'solution_error_units': 'Ошибка в единицах',
      'solution_error_misread': 'Неверно понял вопрос',
      'solution_error_incomplete': 'Не довёл до конца',
      'solution_error_no_work': 'Решение не записано',
      'solution_error_none': 'Без ошибок',
      'solution_work_full': 'Полное решение',
      'solution_work_partial': 'Частично',
      'solution_work_none': 'Нет решения',
      'wd_7': 'Вс',
      'from_material': 'Из моего материала',
      'from_material_hint':
          'Загрузите конспект, страницу пособия или PDF/DOCX — ИИ выделит темы и составит вопросы именно по этому материалу.',
      'material_title': 'Мой материал',
      'material_branch': 'Раздел',
      'material_files': 'Файлы',
      'material_pick_file': 'PDF / DOCX',
      'material_limit': 'До 6 файлов за раз, каждый до 8 МБ.',
      'material_upload': 'Загрузить и прочитать',
      'material_reading': 'Читается…',
      'material_ready': 'Прочитано',
      'material_failed': 'Текст не извлечён',
      'material_no_text': 'В этом PDF нет текстового слоя — это скан. Загрузите как фото.',
      'material_bad_photo': 'Фото не читается — загрузите более чёткое.',
      'material_derive': 'Определить темы',
      'material_deriving': 'ИИ выделяет темы…',
      'material_pick_topic': 'Выберите тему для теста',
      'material_no_branch': 'Сначала добавьте раздел — темы добавляются в раздел.',
      'material_need_file': 'Добавьте хотя бы один файл или фото',
      'no_groups_for_subject': 'У вас нет групп по этому предмету.',
      'titul_title': 'Бумажный тест и бланк',
      'titul_body':
          'В PDF для каждого ученика — вопросы и на последней странице бланк ответов. Распечатайте, а после заполнения отсканируйте бланки.',
      'titul_download': 'Скачать PDF и бланк',
      'scan_hint': 'Сфотографируйте заполненные бланки — ИИ прочитает и оценит каждого ученика.',
      'teacher_solution_upload': 'Загрузить лист решений',
      'teacher_solution_body':
          'Сфотографируйте лист, где ученик решал на бумаге — ИИ разберёт способ решения и добавит результат в профиль ученика.',
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
      'variant_mode': 'Variant type',
      'variant_same': 'Same for everyone',
      'variant_unique': 'Individual',
      'question_types': 'Question types',
      'question_types_auto_hint':
          'Left unset, the AI still only writes single-correct-answer questions for now.',
      'question_type_single_choice': 'Single correct answer',
      'question_type_multiple_choice': 'Multiple correct answers',
      'question_type_image_based': 'Image-based',
      'question_type_drag_and_drop': 'Matching',
      'drag_and_drop_hint': 'Pick the matching letter for each number.',
      'drag_and_drop_pick': 'Pick',
      'multi_choice_hint': 'You can mark more than one correct answer',
      'previous_question': 'Back',
      'unanswered_title': 'Some questions are unanswered',
      'unanswered_body': '{n} unanswered. Unanswered questions count as wrong.',
      'finish_anyway': 'Finish anyway',
      'keep_answering': 'Go back',
      'media_not_attached': 'No file attached',
      'attach_media': 'Attach a file',
      'correction_unsupported_type':
          'Correcting this question type isn\'t supported yet here — edit it in the web panel.',
      'advanced_settings': 'Advanced settings',
      'shuffle_questions': 'Shuffle question order',
      'shuffle_answers': 'Shuffle answer order',
      'show_answers': 'Show the correct answer after submitting',
      'show_explanation': 'Show with an explanation',
      'allow_calculator': 'Allow a calculator',
      'with_images': 'Illustrated questions (AI draws them)',
      'view_variants': 'View variants',
      'common_paper': 'Common variant',
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
      'practice_test': 'Practice test',
      'create_practice_test': 'Create a practice test',
      'pick_subject': 'Subject',
      'add_branch': '+ New section',
      'add_topic': '+ New topic',
      'new_branch_title': 'New section',
      'new_topic_title': 'New topic',
      'name_field_label': 'Name',
      'hint_field_label': 'Note (optional)',
      'download_pdf': 'Download PDF',
      'pdf_preparing': 'Preparing the PDF...',
      'pdf_failed': 'Could not get the PDF.',
      'scan_answers': 'Scan paper answers',
      'send_to_students': 'Send to students',
      'send_again': 'Send again',
      'not_sent_yet': 'Not sent yet — students cannot see this test',
      'sent_to_students': 'Sent',
      'scan_upload': 'Choose photos',
      'scan_empty': 'No scanned sheets yet.',
      'scan_reading': 'Reading',
      'scan_matched': 'Graded',
      'scan_unmatched': 'Student not found',
      'scan_failed': 'Could not read',
      'assign_to_student': 'Attach to a student',
      'review_answers': 'Review answers',
      'your_answer_label': 'Chosen answer',
      'correct_answer_label': 'Correct answer',
      'no_answer': 'No answer given',
      'save_correction': 'Save the correction',
      'score_updated': 'Score updated',
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
      'open_action': 'Open',
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
      'knowledge_title': 'AI memory',
      'knowledge_body': 'Upload photos of tests you wrote or papers your students worked on. The AI learns from the questions and mistakes, so the next tests go deeper.',
      'knowledge_upload_body': 'Photograph each page flat and in good light. The AI reads the questions, the answers and the students\' mistakes.',
      'knowledge_privacy': 'Your questions guide only your center\'s tests. Other centers get general lessons (typical mistakes), never the question text.',
      'knowledge_home_title': 'Teach the AI',
      'knowledge_home_body': 'The AI learns from your tests and worked papers',
      'knowledge_new': 'New upload',
      'knowledge_upload': 'Upload and analyse',
      'knowledge_name': 'Name',
      'knowledge_name_hint': 'e.g. Grade 9 algebra quiz',
      'knowledge_kind_test': 'Test',
      'knowledge_kind_worked': 'Worked papers',
      'knowledge_kind_material': 'Material',
      'knowledge_pages': 'Pages',
      'knowledge_pages_word': 'pages',
      'knowledge_questions_word': 'questions',
      'knowledge_lessons_word': 'lessons',
      'knowledge_need_photo': 'Add at least one photo',
      'knowledge_need_name': 'Enter a name',
      'knowledge_uploaded': 'Uploaded — the AI is analysing it',
      'knowledge_empty': 'Nothing uploaded yet. Photograph your first test.',
      'knowledge_state_queued': 'Queued',
      'knowledge_state_analyzing': 'Analysing',
      'knowledge_state_done': 'Done',
      'knowledge_state_failed': 'Failed',
      'knowledge_kind_exemplar': 'Example question',
      'knowledge_kind_misconception': 'Typical mistake',
      'knowledge_kind_pitfall': 'Shallow pattern',
      'knowledge_kind_insight': 'Insight',
      'knowledge_shared': 'Shared with all centers',
      'knowledge_private': 'Your center only',
      'knowledge_depth': 'depth',
      'knowledge_delete': 'Delete',
      'knowledge_delete_confirm': 'The upload and what it taught will be removed. Continue?',
      'knowledge_cancel': 'Cancel',
      'knowledge_retry': 'Analyse again',
      'knowledge_refresh': 'Refresh',
      'knowledge_analyzing_note': 'Takes one to five minutes. You can leave this screen.',
      'solution_upload_title': 'Upload your worked solutions',
      'solution_upload_body':
          'Your teacher asked for the sheet you solved on. Photograph each page clearly — AI will review how you worked. Photos are deleted after the analysis.',
      'solution_convention_title': 'How to fill in the sheet',
      'solution_convention_1': 'Write the question number in the margin: 1',
      'solution_convention_2': 'Solve it, then draw a horizontal line under it',
      'solution_convention_3': 'Then 2, 3 and so on — the same way',
      'solution_retry_notice': 'The last sheet could not be read. Take a sharper photo in good light and upload again.',
      'solution_camera': 'Camera',
      'solution_gallery': 'Gallery',
      'solution_pages_label': 'Pages',
      'solution_upload_and_submit': 'Upload and submit',
      'solution_upload': 'Upload',
      'solution_uploaded': 'Sheet uploaded',
      'solution_need_one': 'Add a photo of at least one page.',
      'solution_pending_title': 'Upload your worked sheet',
      'solution_pending_retry': 'Sheet unreadable — upload again',
      'solution_analysis': 'Solution analysis',
      'solution_refresh': 'Refresh',
      'solution_refresh_hint': 'The analysis usually takes a few minutes.',
      'solution_method': 'Working style',
      'solution_strengths': 'Strengths',
      'solution_weaknesses': 'Weaknesses',
      'solution_recommendations': 'Recommendations',
      'solution_legibility': 'Legibility',
      'solution_errors': 'Mistakes',
      'solution_guessed': 'Guessed',
      'solution_no_work': 'No work',
      'solution_questions': 'By question',
      'solution_question_suffix': 'question',
      'solution_required_toggle': 'Require a worked solution sheet',
      'solution_required_hint':
          'At the end of the test the student photographs their worked sheet; AI reviews how they solved it.',
      'solution_sample_pdf': 'Sample sheet (PDF)',
      'solution_required_note': 'Worked solution sheet required',
      'guess_suspected': 'Possibly guessed',
      'solution_state_waiting': 'Waiting for analysis',
      'solution_state_analyzing': 'Analyzing',
      'solution_state_done': 'Analysis ready',
      'solution_state_failed': 'Unreadable — upload again',
      'solution_state_none': 'Not uploaded',
      'solution_error_calculation': 'Calculation error',
      'solution_error_formula': 'Formula error',
      'solution_error_concept': 'Concept error',
      'solution_error_units': 'Units error',
      'solution_error_misread': 'Misread the question',
      'solution_error_incomplete': 'Did not finish',
      'solution_error_no_work': 'No work written',
      'solution_error_none': 'No mistakes',
      'solution_work_full': 'Full solution',
      'solution_work_partial': 'Partial',
      'solution_work_none': 'No solution',
      'wd_7': 'Sun',
      'from_material': 'From my material',
      'from_material_hint':
          'Upload notes, a textbook page or a PDF/DOCX — the AI finds the topics and builds questions from this very material.',
      'material_title': 'My material',
      'material_branch': 'Section',
      'material_files': 'Files',
      'material_pick_file': 'PDF / DOCX',
      'material_limit': 'Up to 6 files at once, 8 MB each.',
      'material_upload': 'Upload and read',
      'material_reading': 'Reading…',
      'material_ready': 'Read',
      'material_failed': 'No text extracted',
      'material_no_text': 'This PDF has no text layer — it is a scan. Upload it as photos.',
      'material_bad_photo': 'The photo could not be read — upload a sharper one.',
      'material_derive': 'Find topics',
      'material_deriving': 'The AI is finding topics…',
      'material_pick_topic': 'Pick the topic for the test',
      'material_no_branch': 'Add a section first — topics go inside a section.',
      'material_need_file': 'Add at least one file or photo',
      'no_groups_for_subject': 'You have no groups in this subject.',
      'titul_title': 'Paper test and answer sheet',
      'titul_body':
          'The PDF has each student\'s questions and, on the last page, their answer sheet. Print it, and scan the sheets once they are filled in.',
      'titul_download': 'Download PDF and answer sheets',
      'scan_hint': 'Photograph the filled-in answer sheets — the AI reads them and grades every student.',
      'teacher_solution_upload': 'Upload solution sheet',
      'teacher_solution_body':
          'Photograph the sheet the student worked on — the AI analyses how they solved it and adds the result to their profile.',
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
