import 'package:flutter/foundation.dart';

class PollOption {
  final String id;
  final String text;
  final int votes;

  PollOption({required this.id, required this.text, required this.votes});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    final map = json;
    try {
      return PollOption(
        id: map['id']?.toString() ?? '',
        text: map['text']?.toString() ?? map['label']?.toString() ?? '',
        votes: map['votes'] != null ? int.tryParse(map['votes'].toString()) ?? 0 : 0,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[PollOption.fromJson] parse error: $e');
        debugPrint(st.toString());
        debugPrint('payload: ${map.toString()}');
      }
      return PollOption(id: '', text: '', votes: 0);
    }
  }
}

class Poll {
  final String id;
  final String question;
  final List<PollOption> options;
  final bool isExpired;
  final String? userVotedOptionId;

  Poll({required this.id, required this.question, required this.options, this.isExpired = false, this.userVotedOptionId});

  factory Poll.fromJson(Map<String, dynamic> json) {
    final map = json;
    final rawOpts = map['options'] ?? map['choices'] ?? <dynamic>[];
    final List<PollOption> opts = [];
    if (rawOpts is List) {
      for (final e in List<dynamic>.from(rawOpts)) {
        try {
          if (e is Map) {
            opts.add(PollOption.fromJson(Map<String, dynamic>.from(e)));
          } else if (e is String) {
            // sometimes backend returns option id as string; create a minimal option
            opts.add(PollOption(id: e, text: e, votes: 0));
          }
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('[Poll.fromJson] option parse error: $e');
            debugPrint(st.toString());
            debugPrint('option payload: ${e.toString()}');
          }
        }
      }
    }

    try {
      return Poll(
        id: map['id']?.toString() ?? '',
        question: map['question']?.toString() ?? map['title']?.toString() ?? '',
        options: opts,
        isExpired: map['expired'] == true || map['is_expired'] == true,
        userVotedOptionId: map['user_vote']?.toString(),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Poll.fromJson] parse error: $e');
        debugPrint(st.toString());
        debugPrint('payload: ${map.toString()}');
      }
      return Poll(id: '', question: '', options: []);
    }
  }

  Poll copyWithIncrement(String optionId) {
    final newOptions = options.map((o) {
      if (o.id == optionId) return PollOption(id: o.id, text: o.text, votes: o.votes + 1);
      return o;
    }).toList();
    return Poll(id: id, question: question, options: newOptions, isExpired: isExpired, userVotedOptionId: optionId);
  }

  Poll copyWith({List<PollOption>? options, bool? isExpired, String? userVotedOptionId}) {
    return Poll(id: id, question: question, options: options ?? this.options, isExpired: isExpired ?? this.isExpired, userVotedOptionId: userVotedOptionId ?? this.userVotedOptionId);
  }
}
