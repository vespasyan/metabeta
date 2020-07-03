import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:metaphor_beta/tablayouts/chat/chat_screen.dart';
import 'dart:math';
import 'package:metaphor_beta/my_colors.dart';

class SearchMain extends StatefulWidget{
  @override
  _SearchMainState createState() => new _SearchMainState();


}

class _SearchMainState extends State<SearchMain>{


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
    );
  }
}

class SearchContacts extends SearchDelegate<Iterable<Contact>>{

Contact myCon;
Iterable<Contact> _contacts;
static get displayName => null;

Random random;


final myList = [
  'Leonardo',
  'Michelangelo',
  'Rafaello'
];




@override
  List<Widget> buildActions(BuildContext context) {

    return [IconButton(icon: Icon(Icons.clear),
        onPressed: (){
            query = '';
        })];
  }

  @override
  Widget buildLeading(BuildContext context) {

    return IconButton(icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
    ),
        onPressed: (){close(context, null);}
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: implement buildResults
    return null;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    Contact Con;
    //final myList = query.isEmpty??_contacts.where((Con) => true);


    return Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(15, 15, 45, 0.9)
      ),
      child: ListView.builder(
        itemCount: _contacts?.length ?? 0,
        itemBuilder: (BuildContext context, int index) {
          Contact c = query.isEmpty
              ? myList : _contacts.where((m)=> m.displayName.toLowerCase().contains(query));
          //c = _contacts?.elementAt(index);
          c =_contacts?.elementAt(index);

          return Row(
            children: <Widget>[
              Expanded(
                  child: Card(
                    color: Color.fromRGBO(55, 105, 205, 0.25),
                    //semanticContainer: true,
                    shape: StadiumBorder(side: BorderSide(
                      width: 1.0,
                      color: Color(0xff002251),
                      style: BorderStyle.solid,)
                    ),
                    elevation: 5.0,
                    margin: EdgeInsets.only(bottom: 15.0),
                    child: ListTile(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (BuildContext context) =>
                                Chat(peerId: null, peerAvatar: null, userName: null,)));
                      },
                      leading: (c.avatar != null && c.avatar.length > 0)
                          ? CircleAvatar(backgroundImage: MemoryImage(c.avatar),
                          backgroundColor: colors[random.nextInt(4)])
                          : CircleAvatar(
                        backgroundColor: colors[index % colors.length],
                        child: Text(c.displayName.length > 1
                            ? c.displayName?.substring(0, 2)
                            : ""),
                      ),
                      title: Text(c.displayName ?? "", style: TextStyle(color: Colors.white70)),
                    ),
                  )
              ),
            ],
          );
        },
      ),
    );
  }

}