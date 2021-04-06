import 'package:flutter/material.dart';
import 'package:nice_button/NiceButton.dart';
import 'package:nitto_traking/screen/map_activity.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: MyHomePage(title: 'Nitto Tracking'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  var firstColor = Color(0xff5b86e5), secondColor = Color(0xff36d1dc);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,style: TextStyle(color: Colors.white),),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            NiceButton(
              radius: 7,
              //padding: const EdgeInsets.all(15),
              background: firstColor,
              text: "Start Tracking",
              icon: Icons.map,
              gradientColors: [secondColor, firstColor],
              onPressed: ()=>Navigator.of(context).push(MaterialPageRoute(builder: (context)=>MapPage())),
            ),
            SizedBox(height: 20,),
            NiceButton(
              radius: 7,
              //padding: const EdgeInsets.all(15),
              background: firstColor,
              text: "Show Tracking",
              icon: Icons.show_chart,
              gradientColors: [secondColor, firstColor],
              onPressed: () {},
            )
          ],
        ),
      ) // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
