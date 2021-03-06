import 'dart:async';
import 'dart:convert';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:nitto_traking/components/map_pin_pill.dart';
import 'package:nitto_traking/dbHandaler/dbSingleton.dart';
import 'package:nitto_traking/models/land_list_model.dart';
import 'package:nitto_traking/models/pin_pill_info.dart';

const double CAMERA_ZOOM = 16;
const double CAMERA_TILT = 80;
const double CAMERA_BEARING = 30;
const LatLng SOURCE_LOCATION = LatLng(42.747932, -71.167889);
const LatLng DEST_LOCATION = LatLng(37.335685, -122.0605916);
class MapPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MapPageState();
}

class MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin {
  bool isStart=false;
  LatLng _startLocation,_endLocation;
  List<LatLng>_point=[];

  TextEditingController _nameController=new TextEditingController();
  TextEditingController _addressController=new TextEditingController();

  Completer<GoogleMapController> _controller = Completer();
  Completer mapCompleter=Completer();
  Set<Marker> _markers = Set<Marker>();
// for my drawn routes on the map
  Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints;
  Position _position;
  String googleAPIKey = 'AIzaSyAdmssGjJ5i8mJ1iylBZfPma5L0QtZoz_E';
// for my custom marker pins
  BitmapDescriptor sourceIcon;
  BitmapDescriptor destinationIcon;
// the user's initial location and current location
// as it moves
  LocationData currentLocation;
// a reference to the destination location
  LocationData destinationLocation;
// wrapper around the location API
  Location location;
  double pinPillPosition = -100;
  PinInformation currentlySelectedPin = PinInformation(
      pinPath: '',
      avatarPath: '',
      location: LatLng(0, 0),
      locationName: '',
      labelColor: Colors.grey);
  PinInformation sourcePinInfo;
  PinInformation destinationPinInfo;

  @override
  void initState() {
    super.initState();

    // create an instance of Location
    _determinePosition().then((value) {
      setState(() {
        _position=value;
        print('location:'+_position.longitude.toString());
      });
    });

    location = new Location();
    polylinePoints = PolylinePoints();

    // subscribe to changes in the user's location
    // by "listening" to the location's onLocationChanged event
    location.onLocationChanged.listen((LocationData cLoc) {
      // cLoc contains the lat and long of the
      // current user's position in real time,
      // so we're holding on to it
      //print(cLoc.longitude);
      /*setState(() {
        polylineCoordinates.add(LatLng(cLoc.latitude, cLoc.longitude));
      });*/
      currentLocation = cLoc;
      updatePinOnMap(cLoc.latitude,cLoc.longitude);
    });
    // set custom marker pins
    setSourceAndDestinationIcons();
    // set the initial location
    //setInitialLocation();
  }
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error(
            'Location permissions are denied');
      }
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
  void setSourceAndDestinationIcons() async {
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.0), 'assets/driving_pin.png')
        .then((onValue) {
      sourceIcon = onValue;
    });

    BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 2.0),
        'assets/destination_map_marker.png')
        .then((onValue) {
      destinationIcon = onValue;
    });
  }

  void setInitialLocation() async {
    // set the initial location by pulling the user's
    // current location from the location's getLocation()
    currentLocation = await location.getLocation();

    // hard-coded destination for this example
    destinationLocation = LocationData.fromMap({
      "latitude": DEST_LOCATION.latitude,
      "longitude": DEST_LOCATION.longitude
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    CameraPosition initialCameraPosition = CameraPosition(
        zoom: CAMERA_ZOOM,
        tilt: CAMERA_TILT,
        bearing: CAMERA_BEARING,
        target: SOURCE_LOCATION);
    if (currentLocation != null) {
      initialCameraPosition = CameraPosition(
          target: LatLng(_position.latitude, _position.longitude),
          zoom: CAMERA_ZOOM,
          tilt: CAMERA_TILT,
          bearing: CAMERA_BEARING);
    }
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
              myLocationEnabled: true,
              compassEnabled: true,
              tiltGesturesEnabled: false,
              markers: _markers,
              polylines: _polylines,
              mapType: MapType.normal,
              initialCameraPosition: initialCameraPosition,
              onTap: (LatLng loc) {
                pinPillPosition = -100;
              },
              onMapCreated: (GoogleMapController controller) {
                controller.setMapStyle(Utils.mapStyles);
                //_controller.complete(controller);
                if (!mapCompleter.isCompleted) {
                  mapCompleter.complete(controller);
                  //qmapController = controller;
                }
                // my map has completed being created;
                // i'm ready to show the pins on the map
                showPinsOnMap();
              }),
          MapPinPillComponent(
              pinPillPosition: pinPillPosition,
              currentlySelectedPin: currentlySelectedPin),
          !isStart?Padding(
            padding: const EdgeInsets.only(bottom: 50,left: 10),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: 180,
                child: OutlinedButton(
                  onPressed: (){
                    setState(() {
                      isStart=true;
                      _startLocation=LatLng(currentLocation.latitude, currentLocation.longitude);
                      _point.add(LatLng(currentLocation.latitude, currentLocation.longitude));
                    });
                  },
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0),)),
                  ),
                  child: Row(
                    children: [
                      Text('Start Navigate',style: TextStyle(fontWeight: FontWeight.w500,fontSize: 18,color: Colors.red),),
                      Icon(
                        Icons.navigation_outlined,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              )
            ),
          ):Text(''),
          isStart?Padding(
            padding: EdgeInsets.only(right: 10,bottom: 50),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    child: OutlinedButton(
                      onPressed: (){
                        setState(() {
                          _point.add(LatLng(currentLocation.latitude,currentLocation.latitude));
                        });
                      },
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0),)),
                      ),
                      child: Row(
                        children: [
                          Text('Next',style: TextStyle(fontWeight: FontWeight.w500,fontSize: 18,color: Colors.green),),
                          Icon(
                            Icons.next_plan_outlined,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 120,
                    child: OutlinedButton(
                      onPressed: (){
                        setState(() {
                          _point.add(LatLng(currentLocation.latitude, currentLocation.longitude));
                          _endLocation=LatLng(currentLocation.latitude, currentLocation.longitude);
                        });
                        singleTextAlertDailog(context);
                      },
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0),)),
                      ),
                      child: Row(
                        children: [
                          Text('Finish',style: TextStyle(fontWeight: FontWeight.w500,fontSize: 18,color: Colors.cyan),),
                          Icon(
                            Icons.navigation_outlined,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  )
                ],
          ),
              ),
            ),):Text('')
        ],
      ),
    );
  }

  void showPinsOnMap() {
    // get a LatLng for the source location
    // from the LocationData currentLocation object
    var pinPosition;
    if(_position!=null){
      pinPosition=LatLng(_position.latitude, _position.longitude);
    }

    // get a LatLng out of the LocationData object
    var destPosition=LatLng(destinationLocation.latitude, destinationLocation.longitude);

    sourcePinInfo = PinInformation(
        locationName: "Start Location",
        location: pinPosition,
        pinPath: "assets/driving_pin.png",
        avatarPath: "assets/friend1.jpg",
        labelColor: Colors.blueAccent);

    destinationPinInfo = PinInformation(
        locationName: "End Location",
        location: destPosition,
        pinPath: "assets/destination_map_marker.png",
        avatarPath: "assets/friend2.jpg",
        labelColor: Colors.purple);

    // add the initial source location pin
    _markers.add(Marker(
        markerId: MarkerId('sourcePin'),
        position: pinPosition,
        onTap: () {
          setState(() {
            currentlySelectedPin = sourcePinInfo;
            pinPillPosition = 0;
          });
        },
        icon: sourceIcon));
    // destination pin
    _markers.add(Marker(
        markerId: MarkerId('destPin'),
        position: destPosition,
        onTap: () {
          setState(() {
            currentlySelectedPin = destinationPinInfo;
            pinPillPosition = 0;
          });
        },
        icon: destinationIcon));
    // set the route lines on the map from source to destination
    // for more info follow this tutorial
    setPolylines();
  }

  void setPolylines() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleAPIKey,
        PointLatLng(_position.latitude,  _position.longitude),
        PointLatLng(currentLocation.latitude,currentLocation.longitude),
        travelMode: TravelMode.walking,
        wayPoints: [PolylineWayPoint(location: "Dhaka")]
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });

      setState(() {
        _polylines.add(Polyline(
            width: 2, // set the width of the polylines
            polylineId: PolylineId("poly"),
            color: Color.fromARGB(255, 40, 122, 198),
            points: polylineCoordinates));
      });
    }
  }

  void updatePinOnMap(double lat,double long) async {
    // create a new CameraPosition instance
    // every time the location changes, so the camera
    // follows the pin as it moves with an animation
    CameraPosition cPosition = CameraPosition(
      zoom: CAMERA_ZOOM,
      tilt: CAMERA_TILT,
      bearing: CAMERA_BEARING,
      target: LatLng(lat, long),
    );
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));
    // do this inside the setState() so Flutter gets notified
    // that a widget update is due
    setState(() {
      // updated position
      var pinPosition =
      LatLng(lat, long);

      sourcePinInfo.location = pinPosition;

      // the trick is to remove the marker (by id)
      // and add it again at the updated location
      _markers.removeWhere((m) => m.markerId.value == 'sourcePin');
      _markers.add(Marker(
          markerId: MarkerId('sourcePin'),
          onTap: () {
            setState(() {
              currentlySelectedPin = sourcePinInfo;
              pinPillPosition = 0;
            });
          },
          position: pinPosition, // updated position
          icon: sourceIcon));
    });
  }
  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;

  singleTextAlertDailog(BuildContext context){
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
          title: Center(child: Text("Save Land",style: TextStyle(fontWeight: FontWeight.w600),),),
          content: Container(
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextFormField(
                  //decoration: new InputDecoration(labelText: "Enter your number"),
                  //keyboardType: TextInputType.multiline,
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Enter Land Name",
                    labelStyle: TextStyle(color: Colors.black,fontWeight: FontWeight.w400),
                    fillColor: Colors.white,
                    hintText: "Land Name",
                    //hintStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w300),
                    /*suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: (){
                      setState(() {
                        _checkTypeController.clear();
                      });
                    },
                  ),*/
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7.0),
                      borderSide: BorderSide(
                          color:Colors.cyan,
                          width: 2
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7.0),
                      borderSide: BorderSide(
                        color: Colors.cyan,
                        width: 2.0,
                      ),
                    ),
                  ),
                  validator: (text) =>
                  text == null && text.isEmpty
                      ? 'Cheque Type is not empty'
                      : text,
                  onChanged: (value){
                    /*setState(() {
                    _chequeType=value;
                  });*/
                  }, // Only numbers can be entered
                ),
                SizedBox(height: 10,),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: "Enter Address",
                    labelStyle: TextStyle(color: Colors.black,fontWeight: FontWeight.w400),
                    fillColor: Colors.white,
                    hintText: "Address",
                    //hintStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w300),
                    /*suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: (){
                      setState(() {
                        _checkTypeController.clear();
                      });
                    },
                  ),*/
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7.0),
                      borderSide: BorderSide(
                          color:Colors.cyan,
                          width: 2
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7.0),
                      borderSide: BorderSide(
                        color: Colors.cyan,
                        width: 2.0,
                      ),
                    ),
                  ),
                  validator: (text) =>
                  text == null && text.isEmpty
                      ? 'Cheque Type is not empty'
                      : text,
                  onChanged: (value){
                    /*setState(() {
                    _chequeType=value;
                  });*/
                  }, // Only numbers can be entered
                )
              ],
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 100),
              child:  RaisedButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7.0),
                    side: BorderSide(color: Colors.cyan)),
                onPressed: () async{
                  Map<String,dynamic>_task={
                    'landName':_nameController.text,
                    'address':_addressController.text,
                    'startPoint':_startLocation,
                    'endPoint':_endLocation,
                    'point':_point
                  };
                  //await DBProvider.db.insertNotification(LandListModel.fromJson(_task));
                  Navigator.of(context).pop();
                },
                color: Colors.cyan,
                textColor: Colors.white,
                child: Text("Save".toUpperCase(),
                    style: TextStyle(fontSize: 15,fontWeight: FontWeight.w400)),
              ),)
          ],
        );
      },
    );
  }
}

class Utils {
  static String mapStyles = '''[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dadada"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#c9c9c9"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  }
]''';
}
