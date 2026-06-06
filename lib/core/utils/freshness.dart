enum Freshness { today, yesterday, old }

Freshness determineFreshness(DateTime? dt) {
  if (dt == null) return Freshness.old;
  final now = DateTime.now();
  final local = dt.toLocal();
  final diff = DateTime(now.year, now.month, now.day).difference(DateTime(local.year, local.month, local.day)).inDays;
  if (diff == 0) return Freshness.today;
  if (diff == 1) return Freshness.yesterday;
  return Freshness.old;
}

String formatFreshnessTag(DateTime? dt) {
  final f = determineFreshness(dt);
  switch (f) {
    case Freshness.today:
      return 'TODAY';
    case Freshness.yesterday:
      return 'YESTERDAY';
    case Freshness.old:
      return 'OLD';
  }
}

int freshnessPriority(DateTime? dt) {
  final f = determineFreshness(dt);
  switch (f) {
    case Freshness.today:
      return 0;
    case Freshness.yesterday:
      return 1;
    case Freshness.old:
      return 2;
  }
}
