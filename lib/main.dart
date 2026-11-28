import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const ink = Color(0xFF101D46);
const blue = Color(0xFF3949D8);
const violet = Color(0xFF655BE8);
const lime = Color(0xFFB8F34A);
const bg = Color(0xFFF3F5FC);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  }
  runApp(const NetlifyHealthApp());
}

class NetlifyHealthApp extends StatelessWidget {
  const NetlifyHealthApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Netlify Health',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: blue, primary: blue),
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    ),
    home: supabaseUrl.isEmpty || supabaseKey.isEmpty
      ? const SetupRequiredPage()
      : const AuthGate(),
  );
}

class SetupRequiredPage extends StatelessWidget {
  const SetupRequiredPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Padding(
      padding: EdgeInsets.all(28),
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 520), child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandMark(), SizedBox(height: 24),
          Text('Connect your health space', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: ink)),
          SizedBox(height: 10),
          Text('Netlify Health needs your Supabase project URL and publishable key to securely create accounts and save health records. Configure SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY using --dart-define. The app will not create pretend accounts or sample records.', style: TextStyle(height: 1.55, color: Color(0xFF59627B))),
        ],
      )),
    )),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: Supabase.instance.client.auth.onAuthStateChange,
    builder: (context, snapshot) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return const AuthPage();
      return ProfileGate(key: ValueKey(user.id), userId: user.id);
    },
  );
}

class ProfileGate extends StatelessWidget {
  const ProfileGate({super.key, required this.userId});
  final String userId;
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: Supabase.instance.client.from('profiles').select().eq('user_id', userId).maybeSingle(),
    builder: (context, snap) {
      if (snap.hasError) return ErrorPage(message: 'Could not load your profile: ${snap.error}', onRetry: () => (context as Element).markNeedsBuild());
      if (snap.connectionState != ConnectionState.done) return const LoadingPage();
      if (snap.data == null) return ProfileSetupPage(userId: userId);
      return HealthShell(profile: snap.data!);
    },
  );
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.message, required this.onRetry});
  final String message; final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(
    padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_rounded, size: 48, color: blue), const SizedBox(height: 16),
      const Text('Something needs attention', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 16), FilledButton(onPressed: onRetry, child: const Text('Try again')),
    ]),
  )));
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 58, height: 58, decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(19),
      gradient: const LinearGradient(colors: [blue, violet], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ), child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 32),
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}
class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController(), password = TextEditingController();
  bool register = false, busy = false;
  String? error;
  Future<void> submit() async {
    setState(() { busy = true; error = null; });
    try {
      if (register) {
        final result = await Supabase.instance.client.auth.signUp(email: email.text.trim(), password: password.text);
        if (result.session == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check your email to confirm your account, then sign in.')));
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(email: email.text.trim(), password: password.text);
      }
    } on AuthException catch (e) { setState(() => error = e.message); }
      catch (e) { setState(() => error = 'Could not connect. Check your internet and try again.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(decoration: const BoxDecoration(gradient: LinearGradient(
      colors: [Color(0xFF303BD0), Color(0xFF625AE8), Color(0xFF2D75B8)],
      begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Center(child: SingleChildScrollView(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460), child: Padding(
          padding: const EdgeInsets.all(26), child: Container(
            padding: const EdgeInsets.all(26), decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .94), borderRadius: BorderRadius.circular(30)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const BrandMark(), const SizedBox(height: 24),
              Text(register ? 'Create your account' : 'Welcome back', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 8), Text(register ? 'Start building healthier everyday habits.' : 'Your health journey continues here.', style: const TextStyle(color: Color(0xFF66708A))),
              const SizedBox(height: 24), const Text('Email address'),
              const SizedBox(height: 7), TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'you@example.com')),
              const SizedBox(height: 16), const Text('Password'),
              const SizedBox(height: 7), TextField(controller: password, obscureText: true, decoration: const InputDecoration(hintText: 'At least 8 characters')),
              if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 22), SizedBox(width: double.infinity, child: FilledButton(
                onPressed: busy ? null : submit, style: FilledButton.styleFrom(backgroundColor: ink, padding: const EdgeInsets.all(17)),
                child: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(register ? 'Create account' : 'Sign in'),
              )),
              Center(child: TextButton(onPressed: () => setState(() { register = !register; error = null; }),
                child: Text(register ? 'Already have an account? Sign in' : 'New to Netlify Health? Create account'))),
            ]),
          ),
        ),
      ))),
    ),
  );
}

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key, required this.userId});
  final String userId;
  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}
class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final name = TextEditingController(), height = TextEditingController(), weight = TextEditingController(), calories = TextEditingController(text: '2000'), allergies = TextEditingController(text: 'None');
  DateTime birth = DateTime(1995, 1, 1);
  String goal = 'Maintain weight', activity = 'Moderate', diet = 'No preference';
  bool busy = false;
  String? error;
  Future<void> save() async {
    if ([name.text, height.text, weight.text, calories.text, allergies.text].any((v) => v.trim().isEmpty) ||
      double.tryParse(height.text) == null || double.tryParse(weight.text) == null || int.tryParse(calories.text) == null) {
      setState(() => error = 'Complete every field with valid values before continuing.'); return;
    }
    setState(() { busy = true; error = null; });
    try {
      final h = double.parse(height.text), w = double.parse(weight.text), c = int.parse(calories.text);
      if (h < 80 || h > 250 || w < 20 || w > 400 || c < 800 || c > 6000) throw const FormatException('Check height, weight and calorie goal ranges.');
      await Supabase.instance.client.from('profiles').upsert({
        'user_id': widget.userId, 'full_name': name.text.trim(),
        'birth_date': DateFormat('yyyy-MM-dd').format(birth), 'height_cm': h,
        'current_weight_kg': w, 'goal': goal, 'activity_level': activity,
        'dietary_preference': diet, 'allergies': allergies.text.trim(),
        'calorie_goal': c, 'water_goal_ml': 2000,
      });
      await Supabase.instance.client.from('weight_entries').upsert({
        'user_id': widget.userId, 'measured_on': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'weight_kg': w, 'note': 'Starting weight',
      }, onConflict: 'user_id,measured_on');
    } on FormatException catch (e) { setState(() => error = e.message); }
      catch (e) { setState(() => error = 'Profile could not be saved. Check your connection and database setup.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  void dispose() { name.dispose(); height.dispose(); weight.dispose(); calories.dispose(); allergies.dispose(); super.dispose(); }
  Widget field(String label, TextEditingController c, {TextInputType type = TextInputType.text}) => Padding(
    padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 7),
      TextField(controller: c, keyboardType: type, decoration: InputDecoration(hintText: label)),
    ]),
  );
  Widget picker(String label, String value, List<String> values, ValueChanged<String?> change) => Padding(
    padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 7),
      DropdownButtonFormField<String>(value: value, items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: change),
    ]),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: SingleChildScrollView(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620),
      child: Padding(padding: const EdgeInsets.all(22), child: Card(
        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const BrandMark(), const SizedBox(height: 20),
          const Text('Complete your profile', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 6), const Text('These details help tailor your daily nutrition and activity goals. Every field is required.'),
          const SizedBox(height: 22),
          field('Full name', name),
          const Text('Date of birth', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 7),
          OutlinedButton.icon(onPressed: () async {
            final d = await showDatePicker(context: context, initialDate: birth, firstDate: DateTime(1920), lastDate: DateTime.now());
            if (d != null) setState(() => birth = d);
          }, icon: const Icon(Icons.calendar_month), label: Text(DateFormat('d MMMM yyyy').format(birth))),
          const SizedBox(height: 14),
          field('Height (cm)', height, type: TextInputType.number),
          field('Current weight (kg)', weight, type: const TextInputType.numberWithOptions(decimal: true)),
          picker('Your goal', goal, ['Lose weight','Maintain weight','Gain weight','Improve fitness'], (v) => setState(() => goal = v!)),
          picker('Activity level', activity, ['Sedentary','Light','Moderate','Active','Very active'], (v) => setState(() => activity = v!)),
          picker('Dietary preference', diet, ['No preference','Vegetarian','Vegan','Pescatarian','Gluten-free','Dairy-free'], (v) => setState(() => diet = v!)),
          field('Food allergies or restrictions (enter None if none)', allergies),
          field('Daily calorie goal (kcal)', calories, type: TextInputType.number),
          if (error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: busy ? null : save, style: FilledButton.styleFrom(backgroundColor: ink, padding: const EdgeInsets.all(17)),
            child: busy ? const CircularProgressIndicator(color: Colors.white) : const Text('Save profile & continue'),
          )),
          Center(child: TextButton(onPressed: () => Supabase.instance.client.auth.signOut(), child: const Text('Sign out'))),
        ])),
      )),
    ))),
  );
}

class Food {
  const Food(this.name, this.serving, this.kcal, this.protein, this.carbs, this.fat, this.type, this.note);
  final String name, serving, type, note;
  final int kcal; final double protein, carbs, fat;
}
const foods = <Food>[
  Food('Oats with banana','1 bowl · 250 g',310,10,55,6,'Breakfast','Oats, banana and milk or fortified alternative'),
  Food('Greek yogurt & berries','1 cup · 200 g',190,18,22,4,'Morning snack','Plain yogurt with mixed berries'),
  Food('Grilled chicken rice bowl','1 bowl · 350 g',520,38,62,12,'Lunch','Grilled chicken, rice and mixed vegetables'),
  Food('Apple & almonds','1 serving · 1 apple + 15 g',180,4,25,9,'Afternoon snack','Fresh apple and unsalted almonds'),
  Food('Salmon with sweet potato','1 plate · 320 g',540,34,48,22,'Dinner','Baked salmon, sweet potato and greens'),
  Food('Cottage cheese','150 g',150,18,6,6,'Evening snack','Plain cottage cheese; check dairy suitability'),
  Food('Tofu quinoa bowl','1 bowl · 320 g',430,22,52,15,'Lunch','Tofu, quinoa and vegetables'),
  Food('Lentil vegetable soup','1 bowl · 300 g',260,16,40,4,'Dinner','Lentils, tomato and vegetables'),
];

class HealthShell extends StatefulWidget {
  const HealthShell({super.key, required this.profile});
  final Map<String, dynamic> profile;
  @override
  State<HealthShell> createState() => _HealthShellState();
}
class _HealthShellState extends State<HealthShell> {
  int tab = 0;
  final titles = const ['Dashboard','Meals','Water','Activity','Progress','Profile'];
  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(profile: widget.profile, onOpen: (i) => setState(() => tab = i)),
      MealsPage(profile: widget.profile),
      WaterPage(profile: widget.profile),
      ActivityPage(),
      ProgressPage(profile: widget.profile),
      ProfilePage(profile: widget.profile),
    ];
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 900;
      return Scaffold(
        appBar: AppBar(title: Row(children: [const BrandMark(), const SizedBox(width: 12), Text('Netlify Health · ${titles[tab]}', style: const TextStyle(fontWeight: FontWeight.w800, color: ink))]),
          actions: [IconButton(tooltip: 'Sign out', onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout_rounded)), const SizedBox(width: 8)]),
        body: Row(children: [
          if (wide) NavigationRail(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('Home')),
              NavigationRailDestination(icon: Icon(Icons.restaurant_menu), label: Text('Meals')),
              NavigationRailDestination(icon: Icon(Icons.water_drop_outlined), label: Text('Water')),
              NavigationRailDestination(icon: Icon(Icons.directions_run), label: Text('Activity')),
              NavigationRailDestination(icon: Icon(Icons.insights), label: Text('Progress')),
              NavigationRailDestination(icon: Icon(Icons.person_outline), label: Text('Profile')),
            ]),
          Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: pages[tab]))),
        ]),
        bottomNavigationBar: wide ? null : NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Meals'),
            NavigationDestination(icon: Icon(Icons.water_drop_outlined), label: 'Water'),
            NavigationDestination(icon: Icon(Icons.directions_run), label: 'Activity'),
            NavigationDestination(icon: Icon(Icons.insights), label: 'Progress'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          ]),
      );
    });
  }
}

class PagePad extends StatelessWidget {
  const PagePad({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(20), child: child);
}
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle});
  final String title; final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink)),
    if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 5), child: Text(subtitle!, style: const TextStyle(color: Color(0xFF69738D)))),
  ]));
}
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = 18});
  final Widget child; final double padding;
  @override
  Widget build(BuildContext context) => Container(padding: EdgeInsets.all(padding), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x0B17234D), blurRadius: 22, offset: Offset(0, 8))]), child: child);
}
class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.label, required this.value, required this.unit, required this.icon, this.progress});
  final String label, value, unit; final IconData icon; final double? progress;
  @override
  Widget build(BuildContext context) => Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(icon, color: blue), const Spacer(), Text(unit, style: const TextStyle(color: Colors.black45))]),
    const SizedBox(height: 14), Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: ink)),
    Text(label, style: const TextStyle(color: Color(0xFF707A91))),
    if (progress != null) Padding(padding: const EdgeInsets.only(top: 12), child: LinearProgressIndicator(value: progress!.clamp(0,1), minHeight: 7, borderRadius: BorderRadius.circular(8), color: lime, backgroundColor: bg)),
  ]));
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.profile, required this.onOpen});
  final Map<String, dynamic> profile; final ValueChanged<int> onOpen;
  @override
  Widget build(BuildContext context) {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return PagePad(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle('Hi, ${profile['full_name']} 👋', subtitle: 'Your health journey starts with small daily steps.'),
      FutureBuilder<List<dynamic>>(
        future: Future.wait([
          Supabase.instance.client.from('meal_logs').select('calories,protein_g,carbs_g,fat_g').eq('user_id',uid).eq('logged_on',today),
          Supabase.instance.client.from('water_logs').select('amount_ml').eq('user_id',uid).eq('logged_on',today),
          Supabase.instance.client.from('activity_logs').select('duration_minutes,steps').eq('user_id',uid).eq('logged_on',today),
        ]),
        builder: (context,s) {
          if (s.hasError) return Panel(child: Text('Could not load today’s summary: ${s.error}'));
          if (!s.hasData) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
          final meals = (s.data![0] as List).cast<Map<String,dynamic>>();
          final water = (s.data![1] as List).cast<Map<String,dynamic>>();
          final activity = (s.data![2] as List).cast<Map<String,dynamic>>();
          final kcal = meals.fold<int>(0,(a,m)=>a+(m['calories'] as num).round());
          final protein = meals.fold<double>(0,(a,m)=>a+(m['protein_g'] as num).toDouble());
          final ml = water.fold<int>(0,(a,w)=>a+(w['amount_ml'] as num).toInt());
          final mins = activity.fold<int>(0,(a,x)=>a+(x['duration_minutes'] as num).toInt());
          final steps = activity.fold<int>(0,(a,x)=>a+(x['steps'] as num).toInt());
          return Column(children: [
            LayoutBuilder(builder:(context,c) {
              final count = c.maxWidth > 700 ? 4 : 2;
              return GridView.count(shrinkWrap:true, physics:const NeverScrollableScrollPhysics(), crossAxisCount:count, mainAxisSpacing:12, crossAxisSpacing:12, childAspectRatio:1.45, children:[
                MetricCard(label:'Calories consumed',value:'$kcal',unit:'kcal',icon:Icons.local_fire_department_outlined,progress:kcal/(profile['calorie_goal'] as num)),
                MetricCard(label:'Protein',value:'${protein.toStringAsFixed(0)} g',unit:'today',icon:Icons.fitness_center),
                MetricCard(label:'Water intake',value:'${(ml/1000).toStringAsFixed(1)} L',unit:'today',icon:Icons.water_drop_outlined,progress:ml/(profile['water_goal_ml'] as num)),
                MetricCard(label:'Activity',value:'$mins min',unit:'$steps steps logged',icon:Icons.directions_walk),
              ]);
            }),
            const SizedBox(height:16),
            Panel(child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('Your daily plan',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800,color:ink)),
              const SizedBox(height:12),
              for (final item in [('Meals','Log breakfast, lunch, dinner and snacks',1,Icons.restaurant_menu),('Water','Keep your hydration on track',2,Icons.water_drop),('Activity','Record movement and exercise',3,Icons.directions_run)])
                ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(backgroundColor:const Color(0xFFEDEEFF),child:Icon(item.$4,color:blue)),title:Text(item.$1,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(item.$2),trailing:const Icon(Icons.arrow_forward_ios,size:15),onTap:()=>onOpen(item.$3)),
            ])),
          ]);
        },
      ),
    ]));
  }
}

class MealsPage extends StatefulWidget {
  const MealsPage({super.key, required this.profile});
  final Map<String,dynamic> profile;
  @override
  State<MealsPage> createState()=>_MealsPageState();
}
class _MealsPageState extends State<MealsPage> {
  bool busy=false;
  Future<void> add(Food f) async {
    setState(()=>busy=true);
    try {
      await Supabase.instance.client.from('meal_logs').insert({
        'user_id':Supabase.instance.client.auth.currentUser!.id,
        'logged_on':DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'meal_type':f.type,'food_name':f.name,'serving':f.serving,'calories':f.kcal,
        'protein_g':f.protein,'carbs_g':f.carbs,'fat_g':f.fat,'completed':true,
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('${f.name} added to today’s plan')));
    } catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not save meal. Please try again.'))); }
    finally {if(mounted)setState(()=>busy=false);}
  }
  @override
  Widget build(BuildContext context) {
    final uid=Supabase.instance.client.auth.currentUser!.id, today=DateFormat('yyyy-MM-dd').format(DateTime.now());
    final types=['Breakfast','Morning snack','Lunch','Afternoon snack','Dinner','Evening snack'];
    return PagePad(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const SectionTitle('Meals & nutrition',subtitle:'A balanced day, planned around your goals. Nutrition values are estimates per serving.'),
      FutureBuilder<List<dynamic>>(future:Supabase.instance.client.from('meal_logs').select().eq('user_id',uid).eq('logged_on',today).order('created_at'),
        builder:(context,s){
          if(s.hasError)return Panel(child:Text('Meals could not load: ${s.error}'));
          if(!s.hasData)return const Center(child:CircularProgressIndicator());
          final logs=s.data!.cast<Map<String,dynamic>>();
          final total=logs.fold<int>(0,(a,m)=>a+(m['calories'] as num).toInt());
          final p=logs.fold<double>(0,(a,m)=>a+(m['protein_g'] as num).toDouble());
          final c=logs.fold<double>(0,(a,m)=>a+(m['carbs_g'] as num).toDouble());
          final fat=logs.fold<double>(0,(a,m)=>a+(m['fat_g'] as num).toDouble());
          return Column(children:[
            Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('Today’s nutrition',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800,color:ink)),
              const SizedBox(height:12),Wrap(spacing:24,runSpacing:12,children:[
                Text('$total kcal',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800,color:blue)),
                Text('Protein ${p.toStringAsFixed(0)} g'),Text('Carbs ${c.toStringAsFixed(0)} g'),Text('Fat ${fat.toStringAsFixed(0)} g'),
              ]),
              const SizedBox(height:10),LinearProgressIndicator(value:(total/(widget.profile['calorie_goal'] as num)).clamp(0,1),color:lime,backgroundColor:bg,minHeight:8,borderRadius:BorderRadius.circular(8)),
              Text('Goal: ${widget.profile['calorie_goal']} kcal',style:const TextStyle(color:Colors.black54)),
            ])),
            const SizedBox(height:16),
            for(final type in types) ...[
              Align(alignment:Alignment.centerLeft,child:Padding(padding:const EdgeInsets.only(bottom:8,top:8),child:Text(type,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:ink)))),
              ...foods.where((f)=>f.type==type).map((f)=>Panel(child:Row(children:[
                Container(width:48,height:48,decoration:BoxDecoration(color:const Color(0xFFEDEEFF),borderRadius:BorderRadius.circular(15)),child:Icon(type.contains('snack')?Icons.spa_outlined:Icons.restaurant,color:blue)),
                const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(f.name,style:const TextStyle(fontWeight:FontWeight.w700)),Text('${f.serving} · ${f.kcal} kcal',style:const TextStyle(color:Colors.black54)),
                  Text('P ${f.protein} g  ·  C ${f.carbs} g  ·  F ${f.fat} g',style:const TextStyle(fontSize:12,color:Colors.black54)),
                  Text(f.note,style:const TextStyle(fontSize:12,color:Colors.black45)),
                ])),
                IconButton(onPressed:busy?null:()=>add(f),icon:const Icon(Icons.add_circle,color:blue,size:30),tooltip:'Add meal'),
              ]))),
              for(final log in logs.where((m)=>m['meal_type']==type)) ListTile(leading:const Icon(Icons.check_circle,color:Colors.green),title:Text(log['food_name']),subtitle:Text('${log['serving']} · ${log['calories']} kcal')),
            ],
            if(logs.isNotEmpty) Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:()=>showModalBottomSheet(context:context,builder:(_)=>SafeArea(child:ListView(children:logs.map((m)=>ListTile(title:Text(m['food_name']),subtitle:Text('${m['calories']} kcal'))).toList()))),icon:const Icon(Icons.history),label:const Text('Today’s meal log'))),
          ]);
        }),
      const SizedBox(height:10),const Text('Nutrition values are estimates. Check food labels and ingredients, especially if you have allergies or dietary restrictions.',style:TextStyle(fontSize:12,color:Colors.black54)),
    ]));
  }
}

class WaterPage extends StatefulWidget {
  const WaterPage({super.key,required this.profile}); final Map<String,dynamic> profile;
  @override State<WaterPage> createState()=>_WaterPageState();
}
class _WaterPageState extends State<WaterPage>{
  Future<void> add(int ml)async{
    try{await Supabase.instance.client.from('water_logs').insert({'user_id':Supabase.instance.client.auth.currentUser!.id,'logged_on':DateFormat('yyyy-MM-dd').format(DateTime.now()),'amount_ml':ml});if(mounted)setState((){});}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Water entry could not be saved.')));}
  }
  @override Widget build(BuildContext context){
    final uid=Supabase.instance.client.auth.currentUser!.id,today=DateFormat('yyyy-MM-dd').format(DateTime.now()),goal=(widget.profile['water_goal_ml'] as num).toInt();
    return PagePad(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const SectionTitle('Water tracker',subtitle:'Small sips add up. Track your hydration throughout the day.'),
      FutureBuilder<List<Map<String,dynamic>>>(future:Supabase.instance.client.from('water_logs').select().eq('user_id',uid).eq('logged_on',today),
        builder:(context,s){if(s.hasError)return Panel(child:Text('Could not load water entries: ${s.error}'));if(!s.hasData)return const Center(child:CircularProgressIndicator());
          final logs=s.data!,total=logs.fold<int>(0,(a,x)=>a+(x['amount_ml'] as num).toInt());
          return Column(children:[
            Panel(child:Column(children:[
              const Icon(Icons.water_drop_rounded,color:blue,size:58),const SizedBox(height:8),
              Text('${(total/1000).toStringAsFixed(2)} L',style:const TextStyle(fontSize:36,fontWeight:FontWeight.w800,color:ink)),
              Text('of ${(goal/1000).toStringAsFixed(1)} L daily goal',style:const TextStyle(color:Colors.black54)),
              const SizedBox(height:18),ClipRRect(borderRadius:BorderRadius.circular(12),child:LinearProgressIndicator(value:(total/goal).clamp(0,1),minHeight:14,color:lime,backgroundColor:bg)),
              const SizedBox(height:18),Wrap(spacing:10,runSpacing:10,children:[for(final ml in [150,250,350,500])FilledButton.tonal(onPressed:()=>add(ml),child:Text('+$ml ml'))]),
            ])),
            const SizedBox(height:16),Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('Today’s entries',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18)),
              if(logs.isEmpty)const Padding(padding:EdgeInsets.all(12),child:Text('No water logged yet. Add your first glass above.')),
              for(final x in logs.reversed)ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.water_drop,color:blue),title:Text('${x['amount_ml']} ml'),subtitle:Text(DateFormat('h:mm a').format(DateTime.parse(x['created_at']).toLocal()))),
            ])),
          ]);
        }),
    ]));
  }
}

class ActivityPage extends StatefulWidget { const ActivityPage({super.key}); @override State<ActivityPage> createState()=>_ActivityPageState(); }
class _ActivityPageState extends State<ActivityPage>{
 final name=TextEditingController(text:'Walking'),minutes=TextEditingController(text:'30'),steps=TextEditingController(text:'3000'),burned=TextEditingController(text:'120');
 Future<void> add()async{
  final m=int.tryParse(minutes.text),s=int.tryParse(steps.text),k=int.tryParse(burned.text);
  if(m==null||s==null||k==null||m<1||m>1440||s<0||k<0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter valid activity values.')));return;}
  try{await Supabase.instance.client.from('activity_logs').insert({'user_id':Supabase.instance.client.auth.currentUser!.id,'logged_on':DateFormat('yyyy-MM-dd').format(DateTime.now()),'activity_name':name.text.trim(),'duration_minutes':m,'steps':s,'calories_burned':k});if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Activity saved')));setState((){});}}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not save activity.')));}
 }
 @override void dispose(){name.dispose();minutes.dispose();steps.dispose();burned.dispose();super.dispose();}
 @override Widget build(BuildContext context){final uid=Supabase.instance.client.auth.currentUser!.id,today=DateFormat('yyyy-MM-dd').format(DateTime.now());
  return PagePad(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   const SectionTitle('Activity',subtitle:'Record movement and exercise. Device step integrations are not connected yet.'),
   Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('Add an activity',style:TextStyle(fontWeight:FontWeight.w800,fontSize:19)),
    const SizedBox(height:12),TextField(controller:name,decoration:const InputDecoration(labelText:'Activity name')),
    const SizedBox(height:10),Wrap(spacing:10,runSpacing:10,children:[
      SizedBox(width:130,child:TextField(controller:minutes,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Minutes'))),
      SizedBox(width:130,child:TextField(controller:steps,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Steps'))),
      SizedBox(width:150,child:TextField(controller:burned,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Calories burned'))),
    ]),
    const SizedBox(height:12),FilledButton(onPressed:add,child:const Text('Save activity')),
   ])),
   const SizedBox(height:16),FutureBuilder<List<Map<String,dynamic>>>(future:Supabase.instance.client.from('activity_logs').select().eq('user_id',uid).eq('logged_on',today).order('created_at',ascending:false),
    builder:(context,s){if(s.hasError)return Panel(child:Text('Could not load activity: ${s.error}'));if(!s.hasData)return const Center(child:CircularProgressIndicator());final rows=s.data!,mins=rows.fold<int>(0,(a,x)=>a+(x['duration_minutes'] as num).toInt()),st=rows.fold<int>(0,(a,x)=>a+(x['steps'] as num).toInt());
     return Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('$mins minutes active',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800,color:ink)),Text('$st steps recorded today'),
      const Divider(height:24),if(rows.isEmpty)const Text('No activity recorded today.'),
      for(final x in rows)ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.directions_run,color:blue),title:Text(x['activity_name']),subtitle:Text('${x['duration_minutes']} min · ${x['steps']} steps · ${x['calories_burned']} kcal')),
     ]));
    }),
  ]));
 }
}

class ProgressPage extends StatefulWidget{const ProgressPage({super.key,required this.profile});final Map<String,dynamic> profile;@override State<ProgressPage> createState()=>_ProgressPageState();}
class _ProgressPageState extends State<ProgressPage>{
 final weight=TextEditingController();
 Future<void> save()async{final w=double.tryParse(weight.text);if(w==null||w<20||w>400){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter a weight between 20 and 400 kg.')));return;}
  try{await Supabase.instance.client.from('weight_entries').upsert({'user_id':Supabase.instance.client.auth.currentUser!.id,'measured_on':DateFormat('yyyy-MM-dd').format(DateTime.now()),'weight_kg':w},onConflict:'user_id,measured_on');if(mounted){weight.clear();setState((){});}}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not save weight.')));}
 }
 @override void dispose(){weight.dispose();super.dispose();}
 @override Widget build(BuildContext context){final uid=Supabase.instance.client.auth.currentUser!.id;
  return PagePad(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   const SectionTitle('Your progress',subtitle:'Review your weight history and build consistent habits.'),
   Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('Log your weight',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),const SizedBox(height:10),
    Row(children:[Expanded(child:TextField(controller:weight,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Weight in kg'))),const SizedBox(width:10),FilledButton(onPressed:save,child:const Text('Save'))]),
   ])),
   const SizedBox(height:16),FutureBuilder<List<Map<String,dynamic>>>(future:Supabase.instance.client.from('weight_entries').select().eq('user_id',uid).order('measured_on',ascending:false).limit(90),
    builder:(context,s){if(s.hasError)return Panel(child:Text('Could not load progress: ${s.error}'));if(!s.hasData)return const Center(child:CircularProgressIndicator());final rows=s.data!;
     return Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Weight history',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
      if(rows.isEmpty)const Padding(padding:EdgeInsets.all(12),child:Text('Your saved measurements will appear here.')),
      for(final x in rows)ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.monitor_weight_outlined,color:blue),title:Text('${x['weight_kg']} kg',style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(DateFormat('d MMM yyyy').format(DateTime.parse(x['measured_on'])))),
     ]));
    }),
  ]));
 }
}

class ProfilePage extends StatelessWidget{
 const ProfilePage({super.key,required this.profile});final Map<String,dynamic> profile;
 @override Widget build(BuildContext context)=>PagePad(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  const SectionTitle('Profile & settings',subtitle:'Your personal health preferences and account controls.'),
  Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Text(profile['full_name'],style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:ink)),
   const SizedBox(height:12),
   for(final row in [
    ('Date of birth',profile['birth_date']),('Height','${profile['height_cm']} cm'),('Current weight','${profile['current_weight_kg']} kg'),
    ('Goal',profile['goal']),('Activity level',profile['activity_level']),('Diet',profile['dietary_preference']),
    ('Allergies / restrictions',profile['allergies']),('Daily calorie goal','${profile['calorie_goal']} kcal'),('Water goal','${profile['water_goal_ml']} ml'),
   ])ListTile(contentPadding:EdgeInsets.zero,title:Text(row.$1,style:const TextStyle(color:Colors.black54)),subtitle:Text(row.$2.toString(),style:const TextStyle(fontWeight:FontWeight.w700))),
   const Divider(),const Text('Account',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18)),
   ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.email_outlined),title:Text(Supabase.instance.client.auth.currentUser?.email??'Signed in')),
   ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.notifications_active_outlined),title:const Text('Reminders'),subtitle:const Text('Notification scheduling is not enabled in this build.')),
   ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.privacy_tip_outlined),title:const Text('Privacy & data'),subtitle:const Text('Your cloud records are protected by Supabase row-level security.')),
   ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.logout),title:const Text('Sign out'),onTap:()=>Supabase.instance.client.auth.signOut()),
  ])),
  const SizedBox(height:12),const Text('Netlify Health provides wellness tracking and is not a medical device. For diagnosis or treatment, consult a qualified healthcare professional.',style:TextStyle(fontSize:12,color:Colors.black54)),
 ]));
}
