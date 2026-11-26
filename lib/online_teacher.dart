import 'package:flutter/material.dart';
import 'cloud_sync.dart';
import 'common.dart';

class OnlineTeacherScreen extends StatefulWidget {
  const OnlineTeacherScreen({super.key});
  @override
  State<OnlineTeacherScreen> createState() => _OnlineTeacherScreenState();
}
class _OnlineTeacherScreenState extends State<OnlineTeacherScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  String? error;
  bool busy = false;
  List<dynamic>? students;
  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  Future<void> _login() async {
    setState(() { busy = true; error = null; });
    final e = await CloudSync.teacherSignIn(email.text, password.text);
    if (e == null) await _load();
    if (mounted) setState(() { busy = false; error = e; });
  }
  Future<void> _load() async {
    try {
      final value = await CloudSync.teacherStudents();
      if (mounted) setState(() { students = value; error = null; });
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Online Teacher Monitoring'),backgroundColor:cDark,
      actions:[IconButton(onPressed:_load,tooltip:'Refresh online records',icon:const Icon(Icons.refresh))]),
    body: ListView(padding:const EdgeInsets.all(18),children:[
      const Text('Connected teacher dashboard',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),const Text('Requires running backend and teacher credentials created on the server. Student records appear after each student joins and syncs.'),
      const SizedBox(height:14),TextField(controller:email,keyboardType:TextInputType.emailAddress,
        decoration:const InputDecoration(labelText:'Server teacher email',border:OutlineInputBorder())),
      const SizedBox(height:12),TextField(controller:password,obscureText:true,
        decoration:const InputDecoration(labelText:'Server teacher password',border:OutlineInputBorder())),
      const SizedBox(height:12),FilledButton(onPressed:busy?null:_login,child:Text(busy?'Connecting...':'CONNECT TO SERVER')),
      if(error!=null) Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,style:const TextStyle(color:Colors.orangeAccent))),
      if(students!=null) ...[
        const SizedBox(height:16),Text('Students: ${students!.length}',style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
        if(students!.isEmpty) const Text('No synchronized students yet.'),
        for(final data in students!) Builder(builder:(context) {
          final s=Map<String,dynamic>.from(data as Map);
          final lessons=(s['lessons'] as List<dynamic>? ?? []);
          final complete=lessons.where((d) => (d as Map)['steps']?['play'] == true).length;
          return Card(color:cPanel,child:ExpansionTile(
            title:Text((s['name'] ?? 'Student').toString()),
            subtitle:Text('$complete / 8 lessons completed'),
            children:[for(final l in lessons) Builder(builder:(context) {
              final lesson=Map<String,dynamic>.from(l as Map);
              final steps=Map<String,dynamic>.from(lesson['steps'] as Map? ?? {});
              final count=steps.values.where((v)=>v==true).length;
              return ListTile(dense:true,title:Text('Lesson ${lesson['number']}'),
                subtitle:Text('$count/4 steps • Score ${lesson['scoreCorrect'] ?? '-'} / ${lesson['scoreTotal'] ?? '-'}'));
            })],
          ));
        }),
        const SizedBox(height:12),OutlinedButton(onPressed:() async {
          await CloudSync.teacherSignOut(); if(mounted)setState(()=>students=null);
        },child:const Text('Disconnect online teacher account')),
      ]
    ]),
  );
}
