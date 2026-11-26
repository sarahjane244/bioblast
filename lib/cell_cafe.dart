import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common.dart';
import 'student_account.dart';

// Cell Café module: client specification, core playable Session 1.
// Other sessions / economy screens are intentionally not represented as complete.
const cafeCream = Color(0xFFFFF4DF);
const cafeBrown = Color(0xFF6B4226);
const cafeOrange = Color(0xFFF28C28);
const cafeBlue = Color(0xFF3FA7E0);
const cafeTeal = Color(0xFF20B2A6);
const cafeGreen = Color(0xFF3BB273);
const cafeRed = Color(0xFFE5484D);

class CellCafeMenu extends StatefulWidget {
  const CellCafeMenu({super.key});
  @override State<CellCafeMenu> createState() => _CellCafeMenuState();
}
class _CellCafeMenuState extends State<CellCafeMenu> {
  @override void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }
  @override void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }
  @override Widget build(BuildContext context) => CafeFrame(child: Column(mainAxisAlignment: MainAxisAlignment.center,children: [
    const Text('☕ BioBlast: CELL CAFÉ',style: TextStyle(fontWeight: FontWeight.w900,fontSize: 34,color:cafeBrown)),
    const SizedBox(height:10),
    const Text('Learn cellular respiration by serving science orders',style:TextStyle(color:cafeBrown,fontSize:16)),
    const SizedBox(height:25),
    CafeButton('▶ PLAY',cafeGreen,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const CafeSessions()))),
    const SizedBox(height:12),
    // Shop and décor are part of the future development phases, not fake active buttons.
    const Text('Shop • My Café • My Items — upcoming modules',style:TextStyle(color:cafeBrown)),
    const SizedBox(height:12),
    Text('Coins: ${Store.coins.value}',style:const TextStyle(color:cafeBrown,fontWeight:FontWeight.bold)),
    const SizedBox(height:18),
    TextButton.icon(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.arrow_back),label:const Text('Back to BioBlast')),
    const SizedBox(height:8),
    const Text('Science tip: Glycolysis occurs in the cytosol without oxygen.',style:TextStyle(color:cafeBrown,fontSize:13)),
  ]));
}
class CafeFrame extends StatelessWidget {
  final Widget child;
  const CafeFrame({super.key,required this.child});
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:cafeCream,body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1250),child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:child)))));
}
class CafeButton extends StatelessWidget {
  final String label; final Color color; final VoidCallback? onPressed;
  const CafeButton(this.label,this.color,this.onPressed,{super.key});
  @override Widget build(BuildContext context)=>SizedBox(width:160,height:50,child:ElevatedButton(onPressed:onPressed,style:ElevatedButton.styleFrom(backgroundColor:color,foregroundColor:Colors.white,disabledBackgroundColor:Colors.grey,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15))),child:Text(label,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800))));
}
class CafeSessions extends StatefulWidget {
  const CafeSessions({super.key});
  @override State<CafeSessions> createState()=>_CafeSessionsState();
}
class _CafeSessionsState extends State<CafeSessions> {
  int best=0;
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{final p=await SharedPreferences.getInstance();if(mounted)setState(()=>best=p.getInt('cafe_${StudentAccount.id}_stars_1')??0);}
  @override Widget build(BuildContext context)=>CafeFrame(child:Column(children:[
    const Text('Choose a Session',style:TextStyle(fontSize:30,fontWeight:FontWeight.bold,color:cafeBrown)),
    const SizedBox(height:16),
    Wrap(spacing:12,runSpacing:12,alignment:WrapAlignment.center,children: List.generate(5,(i){
      final titles=['Glycolysis','Pyruvate Processing','Krebs Cycle','Electron Transport & ATP','Fermentation Challenge'];
      return Container(width:210,padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:cafeBrown,width:2),borderRadius:BorderRadius.circular(15)),child:Column(children:[
        Text('Session ${i+1}',style:const TextStyle(color:cafeBrown,fontWeight:FontWeight.bold)),
        const SizedBox(height:6),Text(titles[i],style:const TextStyle(color:cafeBrown),textAlign:TextAlign.center),
        const SizedBox(height:6),Text(i==0?'Best: $best ★':'Coming in next phase',style:const TextStyle(color:cafeBrown,fontSize:12)),
        const SizedBox(height:10),CafeButton(i==0?'PLAY':'LOCKED',i==0?cafeGreen:Colors.grey,i==0?()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const CafePlay())):null),
      ]));
    })),
    const SizedBox(height:16),TextButton(onPressed:()=>Navigator.pop(context),child:const Text('◀ Back')),
  ]));
}
class CafePlay extends StatefulWidget {
  const CafePlay({super.key});
  @override State<CafePlay> createState()=>_CafePlayState();
}
class _CafePlayState extends State<CafePlay> {
  Map<String,dynamic>? data;
  int orderIndex=0, firstTry=0, coinsEarned=0, tries=0;
  final List<String> picked=[];
  bool prepared=false, animating=false, showHint=false;
  String feedback='Welcome! Select ingredients or answer the order.';
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    final raw=await rootBundle.loadString('assets/cell_cafe/session1.json');
    if(mounted)setState(()=>data=jsonDecode(raw) as Map<String,dynamic>);
  }
  Map<String,dynamic> get order => Map<String,dynamic>.from((data!['orders'] as List)[orderIndex] as Map);
  List<String> get required=>List<String>.from(order['ingredients']??[]);
  bool get isChoose=>order['type']=='choose';
  void pick(String item){
    if(prepared||animating)return;
    if(picked.contains(item))return;
    if(!required.contains(item)){
      setState((){tries++;feedback='Not quite! ${order['explanation']}';});return;
    }
    setState((){picked.add(item);feedback='Excellent! You selected $item.';});
  }
  void choose(String item){
    if(item!=order['answer']){setState((){tries++;feedback='Not quite! ${order['explanation']}';});return;}
    setState((){prepared=true;feedback='Correct! ${order['explanation']}';});
  }
  Future<void> prepare()async{
    if(prepared||animating||picked.length!=required.length)return;
    setState(()=>animating=true);
    await Navigator.push(context,MaterialPageRoute(builder:(_)=>CafeMachine(order:order)));
    if(mounted)setState((){animating=false;prepared=true;feedback='The process is complete. Now SERVE your customer!';});
  }
  Future<void> serve()async{
    if(!prepared)return;
    final award=tries==0?10:(tries==1?5:2);
    if(tries==0)firstTry++;
    coinsEarned+=award;
    Store.addCoins(award);
    if(orderIndex==4){
      final stars=firstTry==5?3:(firstTry>=4?2:1);
      if(stars==3){coinsEarned+=10;Store.addCoins(10);}
      final p=await SharedPreferences.getInstance();
      final key='cafe_${StudentAccount.id}_stars_1';
      final old=p.getInt(key)??0;
      await p.setInt(key,stars>old?stars:old);
      // Record the café assessment separately from the existing 8 lessons.
      await p.setInt('cafe_${StudentAccount.id}_first_try_1',firstTry);
      if(!mounted)return;
      Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>CafeResults(stars:stars,firstTry:firstTry,earned:coinsEarned)));
      return;
    }
    setState((){orderIndex++;picked.clear();tries=0;prepared=false;showHint=false;feedback='New customer! Read the order.';});
  }
  @override Widget build(BuildContext context){
    if(data==null)return const CafeFrame(child:Center(child:CircularProgressIndicator()));
    final o=order;
    return CafeFrame(child:Column(children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        TextButton(onPressed:()=>_pause(context),child:const Text('Ⅱ Pause')),
        const Text('SESSION 1 · GLYCOLYSIS',style:TextStyle(fontWeight:FontWeight.bold,fontSize:22,color:cafeBrown)),
        Text('Customer ${orderIndex+1}/5   🪙 ${Store.coins.value}',style:const TextStyle(color:cafeBrown,fontSize:16)),
      ]),
      const SizedBox(height:12),
      Wrap(spacing:14,runSpacing:14,children:[
        _panel('CUSTOMER: ${o['customer']}', SizedBox(width:490,child:Column(children:[
          Text('${o['question']}',style:const TextStyle(color:cafeBrown,fontSize:19),textAlign:TextAlign.center),
          const SizedBox(height:8), Text(isChoose?'Choose the correct answer':'Recipe: ${o['recipe']}',style:const TextStyle(color:cafeTeal,fontWeight:FontWeight.bold)),
          const SizedBox(height:12),
          if(isChoose) ...[
            for(final a in List<String>.from(o['options'])) Padding(padding:const EdgeInsets.only(bottom:8),child:CafeButton(a,cafeBlue,prepared?null:()=>choose(a))),
          ] else ...[
            const Text('Preparation slots',style:TextStyle(color:cafeBrown)),
            Wrap(spacing:8,children:List.generate(required.length,(i)=>ActionChip(label:Text(i<picked.length?picked[i]:'+'),onPressed:i<picked.length&&!prepared?()=>setState(()=>picked.removeAt(i)):null))),
            const SizedBox(height:12),
            Text('${data!['machine']} • ${data!['location']}',style:const TextStyle(color:cafeBrown,fontWeight:FontWeight.bold)),
            const SizedBox(height:8),
            Wrap(spacing:8,children:[CafeButton('PREPARE',cafeOrange,picked.length==required.length&&!prepared?prepare:null),CafeButton('CLEAR',Colors.grey,picked.isNotEmpty&&!prepared?()=>setState(()=>picked.clear()):null)]),
          ],
          const SizedBox(height:12),CafeButton('SERVE',cafeGreen,prepared?serve:null),
        ]))),
        _panel('INGREDIENT SHELF + HELPER',SizedBox(width:410,child:Column(children:[
          if(!isChoose)Wrap(spacing:7,runSpacing:8,children:[for(final i in const ['Glucose','Oxygen','Pyruvate','Acetyl-CoA','NADH','FADH₂','ADP','Phosphate','Coenzyme A','Oxaloacetate','H⁺','Water']) ActionChip(label:Text(i),onPressed:()=>pick(i))]),
          const SizedBox(height:12),CafeButton('HINT',cafeBlue,()=>setState(()=>showHint=true)),
          if(showHint) Padding(padding:const EdgeInsets.all(10),child:Text('${o['explanation']}',style:const TextStyle(color:cafeBrown))),
          const SizedBox(height:10),Text(feedback,style:const TextStyle(color:cafeBrown,fontWeight:FontWeight.w600),textAlign:TextAlign.center),
        ]))),
      ]),
    ]));
  }
  Widget _panel(String title,Widget body)=>Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:cafeBrown,width:2)),child:Column(children:[Text(title,style:const TextStyle(color:cafeBrown,fontWeight:FontWeight.bold,fontSize:17)),const SizedBox(height:10),body]));
  void _pause(BuildContext context)=>showDialog<void>(context:context,builder:(c)=>AlertDialog(title:const Text('Pause'),content:const Text('Leave this session? Current customer progress will be lost.'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('RESUME')),TextButton(onPressed:(){Navigator.pop(c);Navigator.pop(context);},child:const Text('QUIT'))]));
}
class CafeMachine extends StatefulWidget {
  final Map<String,dynamic> order;
  const CafeMachine({super.key,required this.order});
  @override State<CafeMachine> createState()=>_CafeMachineState();
}
class _CafeMachineState extends State<CafeMachine> {
  int step=0;
  final captions=['Glucose enters glycolysis in the cytosol.','Enzymes break down glucose into two three-carbon pyruvate molecules.','Glycolysis produces 2 NADH and a net gain of 2 ATP. Oxygen is not required.'];
  @override Widget build(BuildContext context)=>CafeFrame(child:Column(children:[
    const Text('GLYCOLYSIS BLENDER · CYTOSOL',style:TextStyle(color:cafeBrown,fontSize:24,fontWeight:FontWeight.bold)),
    const SizedBox(height:20),
    const Text('⬡ Glucose   →   ⚙️ Glycolysis   →   2 Pyruvate + 2 NADH + net 2 ATP',style:TextStyle(color:cafeBrown,fontSize:20,fontWeight:FontWeight.bold)),
    const SizedBox(height:20),
    Text('Step ${step+1} of 3',style:const TextStyle(color:cafeTeal,fontWeight:FontWeight.bold)),
    Padding(padding:const EdgeInsets.all(14),child:Text(captions[step],textAlign:TextAlign.center,style:const TextStyle(color:cafeBrown,fontSize:19))),
    CafeButton(step==2?'CONTINUE':'NEXT STEP',cafeGreen,()=>step==2?Navigator.pop(context):setState(()=>step++)),
    TextButton(onPressed:()=>setState(()=>step=0),child:const Text('↻ Replay')),
  ]));
}
class CafeResults extends StatelessWidget {
  final int stars, firstTry, earned;
  const CafeResults({super.key,required this.stars,required this.firstTry,required this.earned});
  @override Widget build(BuildContext context)=>CafeFrame(child:Column(children:[
    const Text('Session Complete!',style:TextStyle(fontWeight:FontWeight.bold,fontSize:34,color:cafeBrown)),
    const Text('Session 1 · Glycolysis',style:TextStyle(color:cafeBrown)),
    const SizedBox(height:14),Text('${'★'*stars}${'☆'*(3-stars)}',style:const TextStyle(color:Color(0xFFF4C20D),fontSize:45)),
    Text('Correct on first try: $firstTry / 5',style:const TextStyle(color:cafeBrown,fontSize:18)),
    const Text('Customers served: 5 / 5',style:TextStyle(color:cafeBrown,fontSize:18)),
    Text('Coins earned: +$earned  • Balance: ${Store.coins.value}',style:const TextStyle(color:cafeBrown,fontSize:18)),
    const SizedBox(height:10),const Text('You learned: Glycolysis splits glucose into two pyruvate, producing 2 NADH and net 2 ATP in the cytosol without needing oxygen.',textAlign:TextAlign.center,style:TextStyle(color:cafeTeal)),
    const SizedBox(height:18),CafeButton('REPLAY',cafeOrange,()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const CafePlay()))),
    const SizedBox(height:8),TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Session Select')),
  ]));
}
