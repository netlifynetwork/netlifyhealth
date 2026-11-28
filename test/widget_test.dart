import 'package:flutter_test/flutter_test.dart';
import 'package:netlify_health/main.dart';

void main() {
  testWidgets('shows backend setup instructions when credentials are absent', (tester) async {
    await tester.pumpWidget(const NetlifyHealthApp());
    expect(find.text('Connect your health space'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
  });
}
