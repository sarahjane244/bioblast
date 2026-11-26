import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common.dart';
import 'home.dart';
import 'cloud_sync.dart';

class StudentAccount {
  static const _active = 'bioblast_active_student';
  static const _students = 'bioblast_student_profiles';
  static String id = '';
  static String fullName = '';
  static String className = '';
  static bool get signedIn => id.isNotEmpty;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    await select(prefs.getString(_active) ?? '');
  }

  static Future<List<Map<String, String>>> profiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_students) ?? '[]';
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => Map<String, String>.from(e as Map)).toList();
    } catch (_) { return []; }
  }

  static Future<void> select(String studentId) async {
    final all = await profiles();
    final found = all.where((e) => e['id'] == studentId);
    final profile = found.isEmpty ? null : found.first;
    id = profile?['id'] ?? '';
    fullName = profile?['fullName'] ?? '';
    className = profile?['className'] ?? '';
    final prefs = await SharedPreferences.getInstance();
    if (id.isEmpty) { await prefs.remove(_active); } else { await prefs.setString(_active, id); }
    await Store.loadStudent(id);
  }

  static Future<String?> register(String name) async {
    final newName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (newName.split(' ').where((part) => part.isNotEmpty).length < 2) {
      return 'Please enter your first and last name.';
    }
    final all = await profiles();
    // The ID is generated internally to keep each student's offline progress separate.
    // Students do not need to enter or see an ID or section.
    var newId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    while (all.any((p) => p['id'] == newId)) {
      newId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    }
    all.add({'id': newId, 'fullName': newName});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_students, jsonEncode(all));
    await select(newId);
    return null;
  }

  static Future<void> signOut() async {
    id = ''; fullName = ''; className = '';
    await select('');
  }
}

class StudentEntryScreen extends StatefulWidget {
  const StudentEntryScreen({super.key});
  @override
  State<StudentEntryScreen> createState() => _StudentEntryScreenState();
}

class _StudentEntryScreenState extends State<StudentEntryScreen> {
  final name = TextEditingController();
  bool busy = false;
  String? error;
  List<Map<String, String>> existing = [];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final found = await StudentAccount.profiles(); if (mounted) setState(() => existing = found); }
  @override
  void dispose() { name.dispose(); super.dispose(); }
  void _home() { Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false); }
  Future<void> _register() async {
    if (busy) return;
    setState(() { busy = true; error = null; });
    final failure = await StudentAccount.register(name.text);
    if (!mounted) return;
    setState(() => busy = false);
    if (failure == null) { _home(); } else { setState(() => error = failure); }
  }
  Future<void> _select(String value) async {
    if (busy) return;
    setState(() => busy = true);
    await StudentAccount.select(value);
    if (mounted) _home();
  }
  Widget field(TextEditingController controller, String label, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(controller: controller, textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: cBlue),
      filled: true, fillColor: cPanel,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
  );
  @override
  Widget build(BuildContext context) => OrientationLock(portrait: true, child: Scaffold(
    body: SafeArea(child: Container(
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter,end: Alignment.bottomCenter,colors: [cDark, Color(0xFF0A3266), cDark])),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500),
        child: ListView(padding: const EdgeInsets.all(22), children: [
          const SizedBox(height: 20),
          const Icon(Icons.science_rounded, size: 68, color: cGreen),
          const Center(child: Text('BioBlast', style: TextStyle(color: cGreen,fontSize: 42,fontWeight: FontWeight.w900))),
          const SizedBox(height: 8),
          const Center(child: Text('Create your own profile to start learning.',textAlign: TextAlign.center)),
          const SizedBox(height: 22),
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: cPanel,border: Border.all(color:cBlue,width:2),borderRadius:BorderRadius.circular(22)), child: Column(children: [
            const Text('Student Registration',style:TextStyle(fontSize:23,fontWeight:FontWeight.bold)),
            const SizedBox(height: 16),
            field(name,'Full Name (First and Last Name)',Icons.person_rounded),
            if (error != null) Padding(padding:const EdgeInsets.only(bottom:12),child:Text(error!,style:const TextStyle(color: Colors.orangeAccent))),
            SizedBox(width:double.infinity,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:cOrange,foregroundColor:cDark,padding:const EdgeInsets.all(15)),onPressed:busy?null:_register,child:Text(busy?'Saving...':'START LEARNING',style:const TextStyle(fontWeight:FontWeight.bold)))),
            const SizedBox(height:8),
            const Text('Profile and progress are saved on this device. Cloud sync is not connected yet.',textAlign:TextAlign.center,style:TextStyle(fontSize:12,color:Colors.white70)),
          ])),
          if (existing.isNotEmpty) ...[
            const SizedBox(height:24),
            const Text('Already registered on this device? Select your profile:',style:TextStyle(fontWeight:FontWeight.bold)),
            for (final p in existing) Card(color:cPanel,child:ListTile(
              leading:const Icon(Icons.person,color:cGreen),
              title:Text(p['fullName'] ?? ''),
              trailing:const Icon(Icons.arrow_forward_ios,color:cBlue),
              onTap:busy?null:()=>_select(p['id'] ?? ''),
            )),
          ],
        ]))),
    ))),
  );
}

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});
  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final _code = TextEditingController();
  bool _syncing = false;
  String _status = '';
  @override
  void initState() { super.initState(); _trySync(); }
  @override
  void dispose() { _code.dispose(); super.dispose(); }
  Future<void> _trySync({bool enroll = false}) async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final message = enroll ? await CloudSync.enroll(_code.text) : await CloudSync.sync();
    if (mounted) setState(() { _syncing = false; _status = message ?? 'Synced successfully.'; });
  }
  @override
  Widget build(BuildContext context) {
    final done = List<int>.generate(8,(i)=>i+1).where((i)=>Store.isDone('play',i)).length;
    return OrientationLock(portrait:true,child: Scaffold(
      appBar:AppBar(backgroundColor:cDark,title:const Text('My Student Dashboard')),
      body:Container(decoration:const BoxDecoration(gradient:LinearGradient(colors:[cDark,Color(0xFF0A3266)],begin:Alignment.topCenter,end:Alignment.bottomCenter)),
        child:ListView(padding:const EdgeInsets.all(18),children:[
          Card(color:cPanel,child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Student Profile',style:TextStyle(color:cGreen,fontWeight:FontWeight.bold)),
            Text(StudentAccount.fullName,style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold)),
            const SizedBox(height:12),Text('Lessons completed: $done / 8'),
            LinearProgressIndicator(value:done/8,color:cGreen,minHeight:10),
            const SizedBox(height:8),Text('Coins: ${Store.coins.value}'),
            const SizedBox(height:10),
            Text('Sync status: ${Store.pendingSync ? 'Pending upload' : 'No pending changes'}',style:const TextStyle(color:Colors.orangeAccent,fontSize:12)),
          ]))),
          const SizedBox(height: 12),
          Card(color:cPanel, child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('ONLINE PROGRESS SYNC',style:TextStyle(fontWeight:FontWeight.bold,color:cGreen)),
            const SizedBox(height:6),const Text('Use the class join code provided by your teacher once. Your lessons work offline; sync when internet is available.',style:TextStyle(fontSize:12)),
            const SizedBox(height:8),TextField(controller:_code,obscureText:true,decoration:const InputDecoration(labelText:'Class join code',border:OutlineInputBorder())),
            const SizedBox(height:8),Wrap(spacing:8,children:[
              FilledButton(onPressed:_syncing?null:()=>_trySync(enroll:true),child:const Text('JOIN CLASS')),
              OutlinedButton(onPressed:_syncing?null:()=>_trySync(),child:const Text('SYNC NOW')),
            ]),
            if(_status.isNotEmpty) Text(_status,style:const TextStyle(fontSize:12)),
          ]))),
          const SizedBox(height:16),const Text('My Lessons',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
          for(var s=1;s<=8;s++) Card(color:cPanel,child:ListTile(
            leading:Icon(Store.isDone('play',s)?Icons.check_circle:Icons.menu_book,color:Store.isDone('play',s)?cGreen:cBlue),
            title:Text('Lesson $s'),
            subtitle:Text(Store.isDone('play',s)?'Completed':'Not completed'),
            trailing:Text('${['learn','explore','sim','play'].where((k)=>Store.isDone(k,s)).length}/4 steps'),
          )),
          const SizedBox(height:10),
          OutlinedButton.icon(onPressed:() async {await StudentAccount.signOut();if(!context.mounted)return;Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>const StudentEntryScreen()),(_)=>false);},icon:const Icon(Icons.logout),label:const Text('Switch Student')),
        ])),
    ));
  }
}
