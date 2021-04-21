import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LandListModel{
  String landName;
  String address;
  LatLng startPoint;
  LatLng endPoint;
  List<LatLng> point;

  LandListModel({this.landName, this.address, this.startPoint, this.endPoint,this.point});

  LandListModel.fromJson(Map<String,dynamic>json){
    landName=json['landName'];
    address=json['address'];
    startPoint=json['startPoint'];
    endPoint=json['endPoint'];
   if(json['point']!=null){
     point=new List<LatLng>();
     json['point'].forEach((v){
       point.add(LatLng.fromJson(v));
     });
   }
  }

  Map<String,dynamic> toJson(){
    final Map<String,dynamic>data=new Map<String,dynamic>();
    data['landName']=this.landName;
    data['address']=this.address;
    data['startPoint']=this.startPoint;
    data['endPoint']=this.endPoint;
    if(this.point!=null){
      data['point']=this.point.map((e) => e.toJson()).toList();
    }
    return data;
  }
}