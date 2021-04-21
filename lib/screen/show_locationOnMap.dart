import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nitto_traking/models/land_list_model.dart';
class ShowSaveLocation extends StatefulWidget {
  final LandListModel _landListModel;

  ShowSaveLocation(this._landListModel);

  @override
  _ShowSaveLocationState createState() => _ShowSaveLocationState(_landListModel);
}

class _ShowSaveLocationState extends State<ShowSaveLocation> {
  final LandListModel _landListModel;


  _ShowSaveLocationState(this._landListModel);

  GoogleMapController mapController;
  String googleAPIKey = 'AIzaSyAdmssGjJ5i8mJ1iylBZfPma5L0QtZoz_E';
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  @override
  void initState() {
    super.initState();

    /// origin marker
    _addMarker(_landListModel.startPoint, "origin",
        BitmapDescriptor.defaultMarker);

    /// destination marker
    _addMarker(_landListModel.endPoint, "destination",
        BitmapDescriptor.defaultMarkerWithHue(90));
    _getPolyline();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            child: Icon(Icons.arrow_back),
            onPressed: ()=>Navigator.of(context).pop(),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
          body: GoogleMap(
            initialCameraPosition: CameraPosition(
                target: _landListModel.startPoint, zoom: 25),
            myLocationEnabled: true,
            tiltGesturesEnabled: true,
            compassEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            onMapCreated: _onMapCreated,
            markers: Set<Marker>.of(markers.values),
            polylines: Set<Polyline>.of(polylines.values),
          )),
    );
  }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
  }

  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker =
    Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
  }

  _addPolyLine() {
    PolylineId id = PolylineId(_landListModel.landName);
    Polyline polyline = Polyline(
        polylineId: id, color: Colors.red, points: _landListModel.point);
    polylines[id] = polyline;
    setState(() {});
  }

  _getPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleAPIKey,
        PointLatLng(_landListModel.startPoint.latitude, _landListModel.startPoint.longitude),
        PointLatLng(_landListModel.endPoint.latitude, _landListModel.endPoint.longitude),
        travelMode: TravelMode.walking,
        optimizeWaypoints: false,
        wayPoints: [PolylineWayPoint(location: '${_landListModel.point[1].latitude}/${_landListModel.point[1].longitude}',stopOver: true),PolylineWayPoint(location: '2',stopOver: true),PolylineWayPoint(location: '3',stopOver: true),]);
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    _addPolyLine();
  }
}
