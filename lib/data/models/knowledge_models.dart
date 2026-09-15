import '../../core/util/json.dart';

/// Where an upload to the AI memory is.
enum KnowledgeState { queued, analyzing, done, failed }

KnowledgeState _stateOf(String v) => switch (v) {
      'analyzing' => KnowledgeState.analyzing,
      'done' => KnowledgeState.done,
      'failed' => KnowledgeState.failed,
      _ => KnowledgeState.queued,
    };

/// One upload — `POST /teacher/knowledge/source/paging` row.
class KnowledgeSource {
  const KnowledgeSource({
    required this.id,
    required this.title,
    required this.kind,
    required this.state,
    required this.pages,
    required this.error,
    required this.subject,
    required this.summary,
    required this.questions,
    required this.lessons,
    required this.topics,
    required this.createdAt,
  });

  factory KnowledgeSource.fromJson(Map<String, dynamic> j) {
    final result = asMap(j['result']);
    return KnowledgeSource(
      id: asString(j['id']),
      title: asString(j['title']),
      kind: asString(j['kind'], 'test'),
      state: _stateOf(asString(j['state'])),
      pages: asInt(j['pages']),
      error: asStringOrNull(j['error']),
      subject: asStringOrNull(result['subject']),
      summary: asStringOrNull(result['summary']),
      questions: asInt(result['questions']),
      lessons: asInt(result['lessons']),
      topics: asMapList(result['topics']).map((t) => asString(t['label'])).where((t) => t.isNotEmpty).toList(),
      createdAt: asDate(j['created_at']),
    );
  }

  final String id;
  final String title;

  /// `test` · `worked` · `material`.
  final String kind;
  final KnowledgeState state;
  final int pages;
  final String? error;

  /// The subject the AI read off the page.
  final String? subject;
  final String? summary;
  final int questions;
  final int lessons;
  final List<String> topics;
  final DateTime? createdAt;

  bool get inProgress => state == KnowledgeState.queued || state == KnowledgeState.analyzing;
}

/// What one upload taught — an example question or a lesson.
class KnowledgeItem {
  const KnowledgeItem({
    required this.id,
    required this.kind,
    required this.shared,
    required this.topic,
    required this.skill,
    required this.difficulty,
    required this.content,
    required this.questionText,
    required this.options,
    required this.answer,
    required this.depth,
    required this.studentError,
  });

  factory KnowledgeItem.fromJson(Map<String, dynamic> j) {
    final example = asMap(j['example']);
    return KnowledgeItem(
      id: asString(j['id']),
      kind: asString(j['kind']),
      shared: asBool(j['shared']),
      topic: asString(j['topic_label']),
      skill: asStringOrNull(j['skill']),
      difficulty: asStringOrNull(j['difficulty']),
      content: asString(j['content']),
      questionText: asStringOrNull(example['text']),
      options: asStringList(example['options']),
      answer: asStringOrNull(example['answer']),
      depth: asIntOrNull(example['depth']),
      studentError: asStringOrNull(example['student_error']),
    );
  }

  final String id;

  /// `exemplar` · `misconception` · `pitfall` · `insight`.
  final String kind;

  /// A lesson every center learns from; `false` for the center's own question.
  final bool shared;
  final String topic;
  final String? skill;
  final String? difficulty;
  final String content;
  final String? questionText;
  final List<String> options;
  final String? answer;
  final int? depth;
  final String? studentError;
}

/// `GET /teacher/knowledge/source/:id`.
class KnowledgeSourceDetail {
  const KnowledgeSourceDetail({required this.source, required this.items});

  factory KnowledgeSourceDetail.fromJson(Map<String, dynamic> j) => KnowledgeSourceDetail(
        source: KnowledgeSource.fromJson(j),
        items: mapList(j['knowledge'], KnowledgeItem.fromJson),
      );

  final KnowledgeSource source;
  final List<KnowledgeItem> items;
}
