import '../models/user_model.dart';
import '../models/match_model.dart';

class DummyData {
  static List<User> getDummyUsers() {
    return [
      User(
         id: 'test_user_1',
         name: 'Sophia',
         age: 28,
         bio: 'Travel enthusiast and coffee addict',
         imageUrls: ['https://images.unsplash.com/photo-1484608856193-968d2be4080e?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTUyfHxXT01BTnxlbnwwfHwwfHx8MA%3D%3D','https://images.unsplash.com/photo-1469460340997-2f854421e72f?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1yZWxhdGVkfDN8fHxlbnwwfHx8fHw%3D', 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTU0fHxXT01BTnxlbnwwfHwwfHx8MA%3D%3D'],
         interests: ['Travel', 'Coffee', 'Photography','cat'],
         location: 'Abu Dhabi',
      ),

      User(
        id: 'test_user_2',
        name: 'Laila',
        age: 18,
        bio: 'Architectural designer with a passion for sustainable spaces',
        imageUrls: ['https://images.pexels.com/photos/2205647/pexels-photo-2205647.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',],
        interests: ['Sustainable Architecture', 'Interior Design', 'Urban Gardens', 'Pottery'],
        location: 'Dubai',
      ),

      User(
        id: 'user_3',
        name: 'Celena',
        age: 30,
        bio: 'Marine biologist and ocean conservation advocate',
        imageUrls: ['https://images.unsplash.com/photo-1622347434466-147a44cffda7?q=80&w=1935&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D','https://images.unsplash.com/photo-1646553918743-a78a6da06036?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1yZWxhdGVkfDI0fHx8ZW58MHx8fHx8','https://images.unsplash.com/photo-1646634676853-fe6e7cfb7e42?q=80&w=1964&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D','https://images.unsplash.com/photo-1646554782707-8d4451d87242?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1yZWxhdGVkfDN8fHxlbnwwfHx8fHw%3D',],
        interests: ['Ocean Conservation', 'Diving', 'Marine Photography', 'Beach Cleanups'],
        location: 'Abu Dhabi',
      ),

    ];
  }

  static User getCurrentUser() {
    return User(
      id: 'user_123',
      name: 'Alex',
      age: 29,
      bio: 'Tech enthusiast and fitness lover. Enjoy trying new restaurants and travel.',
      imageUrls: ['https://i.pravatar.cc/300?img=33', 'https://i.pravatar.cc/300?img=45'],
      interests: ['Technology', 'Fitness', 'Food', 'Travel'],
      location: 'Manhattan, NY',
    );
  }

  static List<Match> getDummyMatches() {
    return [
      Match(
        id: 'match_1',
        userId: 'user_123',
        matchedUserId: 'user_2',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Match(
        id: 'match_2',
        userId: 'user_123',
        matchedUserId: 'user_5',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  static User? getUserById(String id) {
    final allUsers = [...getDummyUsers(), getCurrentUser()];
    try {
      return allUsers.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }
}