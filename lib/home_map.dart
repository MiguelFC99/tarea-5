import 'dart:collection';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeMap extends StatefulWidget {
  HomeMap({Key key}) : super(key: key);

  @override
  _HomeMapState createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  String _stringTemp;
  final _buscarDirecController = TextEditingController();
  Set<Polyline> _polylines = HashSet<Polyline>();
  List<LatLng> polylineLatLongs = List<LatLng>();

  Set<Marker> _mapMarkers = Set();
  GoogleMapController _mapController;
  Position _currentPosition;
  Position _defaultPosition = Position(
    longitude: 20.608148,
    latitude: -103.417576,
  );
  

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getCurrentPosition(),
      builder: (context, result) {
        if (result.error == null) {
          if (_currentPosition == null) _currentPosition = _defaultPosition;
          return Scaffold(
            appBar: AppBar(
              title: Text("Maps"),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        // return object of type Dialog
                        return AlertDialog(
                          title: new Text("Escribe dirección"),
                          content: Container(
                            height: 50,
                            child: TextField(
                              controller: _buscarDirecController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Dirección',
                              ),
                            ),
                          ),
                          actions: <Widget>[
                            // usually buttons at the bottom of the dialog
                            new FlatButton(
                              child: new Text("Aceptar"),
                              onPressed: () {
                                _stringTemp = _buscarDirecController.text;
                                searchandNavigate(_stringTemp);
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                )
              ],
            ),
            body: Stack(
              children: <Widget>[
                GoogleMap(
                  polylines: _polylines,
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  onMapCreated: _onMapCreated,
                  markers: _mapMarkers,
                  onLongPress: _setMarker,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition.latitude,
                      _currentPosition.longitude,
                    ),
                  ),
                ),
                FloatingActionButton(backgroundColor: Colors.transparent,onPressed: _setPolylines() 
                  
                ),
              ],
            ),
          );
        } else {
          Scaffold(
            body: Center(child: Text("Error!")),
          );
        }
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }


   _setPolylines() {
    
    //polylineLatLongs.add(LatLng(37.74493, -122.42932));
    //polylineLatLongs.add(LatLng(37.74693, -122.41942));
    //polylineLatLongs.add(LatLng(37.74923, -122.41542));
    //polylineLatLongs.add(LatLng(37.74923, -122.42582));

    _polylines.add(
      Polyline(
        polylineId: PolylineId("0"),
        points: polylineLatLongs,
        color: Colors.purple,
        width: 1,
      ),
    );
  }

  void _onMapCreated(controller) {
    setState(() {
      _mapController = controller;
    });
  }

  void _setMarker(LatLng coord) async {
    // get address
    String _markerAddress = await _getGeolocationAddress(
      Position(latitude: coord.latitude, longitude: coord.longitude),
    );

    // add marker
    setState(() {
      _mapMarkers.add(
        Marker(
            markerId: MarkerId(coord.toString()),
            position: coord,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet),
                
            onTap: () {
              
              showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return _containerBottomSheet(
                        coord.toString(), _markerAddress);
                  });
            }
            /*infoWindow: InfoWindow(
            title: coord.toString(),
            snippet: _markerAddress,
          ),*/
            ),
      );
      polylineLatLongs.add(LatLng(coord.latitude,coord.longitude));
    });
  }

  Future<void> _getCurrentPosition() async {
    // get current position
    _currentPosition = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // get address
    String _currentAddress = await _getGeolocationAddress(_currentPosition);

    // add marker
    _mapMarkers.add(
      Marker(
          markerId: MarkerId(_currentPosition.toString()),
          position: LatLng(
            _currentPosition.latitude,
            _currentPosition.longitude,
          ),
          onTap: () {
            
            showModalBottomSheet(
                context: context,
                builder: (context) {
                  return _containerBottomSheet(
                      _currentPosition.toString(), _currentAddress);
                });
          }
          /*infoWindow: InfoWindow(
          title: _currentPosition.toString(),
          snippet: _currentAddress,
        ),*/
          ),

    );
    polylineLatLongs.add(LatLng(_currentPosition.latitude,_currentPosition.longitude));

    // move camera
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition.latitude,
            _currentPosition.longitude,
          ),
          zoom: 15.0,
        ),
      ),
    );
  }

  Future<String> _getGeolocationAddress(Position position) async {
    var places = await Geolocator().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (places != null && places.isNotEmpty) {
      final Placemark place = places.first;
      return "${place.thoroughfare}, ${place.locality}";
    }
    return "No address availabe";
  }

  searchandNavigate(String address) {
    Geolocator().placemarkFromAddress(address).then((result) {
      _mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(
                  result[0].position.latitude, result[0].position.longitude),
              zoom: 10.0)));
    });
  }

  Widget _containerBottomSheet(String titulo, String snip) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text("$titulo",style: TextStyle(color: Colors.black,fontStyle:  FontStyle.italic),),
          SizedBox(height: 20),
          Text("$snip",style: TextStyle(color: Colors.black,fontStyle:  FontStyle.italic),),
        ],
      ),
    );
  }
}
