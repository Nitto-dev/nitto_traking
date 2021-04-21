import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:nitto_traking/models/land_list_model.dart';
import 'package:nitto_traking/screen/show_locationOnMap.dart';

class LandList extends StatefulWidget {
  @override
  _LandListState createState() => _LandListState();
}

class _LandListState extends State<LandList> {
  List<LandListModel>_item=[
    LandListModel(landName: "Basundarha Group",address: '58/cha,WestRazabazar,Framget',startPoint: LatLng(23.754858,90.380430),endPoint:LatLng(23.754750,90.380226),point: [ LatLng(23.754858,90.380430),LatLng(23.754750,90.380226)]),
    LandListModel(landName: "Nitto Digital",address: 'Josimuddi,sector-3,uttora',startPoint: LatLng(23.861358,90.39586),endPoint:LatLng(23.861352,90.395966),point: [LatLng(23.861358,90.39586),LatLng(23.861505,90.395864),LatLng(23.861498,90.395984),LatLng(23.861352,90.395966)]),
  ];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LandList'),
        centerTitle: true,
      ),
      body:Padding(
        padding: EdgeInsets.all(5),
        child: ListView.separated(itemBuilder: (BuildContext context,int index){
          return GestureDetector(
            onTap: ()=>Navigator.of(context).push(MaterialPageRoute(builder: (context)=>ShowSaveLocation(_item[index]))),
            child: Container(
                decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7.0),
            color: Colors.white,
            border: Border.all(color: Colors.cyan,width: 2.0),
                ),
              child: Card(
                elevation: 0.0,
                child: ListTile(
                  title: Text(_item[index].landName,style: TextStyle(fontWeight: FontWeight.w500,fontSize: 18,color: Colors.black),),
                  subtitle: Text(_item[index].address,style: TextStyle(fontSize: 15,fontWeight: FontWeight.w300,color: Colors.black),),
                  trailing: Icon(Icons.location_on_outlined,color: Colors.red,),
                ),
              ),
            ),
          );
        },
            separatorBuilder: (_,int index)=>Divider(),
            itemCount: _item.length),
      ) ,
    );
  }
}
