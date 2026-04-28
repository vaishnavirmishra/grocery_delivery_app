import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'wishlist_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int currentIndex = 0;
  String searchText = "";
  String selectedCategory = "All";

  // ❤️ GET WISHLIST IDS
  Stream<List<String>> getWishlistIds() {
    return _firestore
        .collection("wishlist")
        .doc(widget.userId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null || data["items"] == null) return [];
      return (data["items"] as Map<String, dynamic>).keys.toList();
    });
  }

  // 🛒 ADD TO CART
  Future<void> addToCart(Map<String, dynamic> product) async {
    final ref = _firestore.collection("cart").doc(widget.userId);
    final snap = await ref.get();

    if (snap.exists &&
        snap.data() != null &&
        snap.data()!["items"] != null &&
        snap.data()!["items"][product["id"]] != null) {
      await ref.update({
        "items.${product["id"]}.quantity": FieldValue.increment(1),
      });
    } else {
      await ref.set({
        "items": {
          product["id"]: {
            ...product,
            "quantity": 1,
          }
        }
      }, SetOptions(merge: true));
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CartScreen()),
      );
    }
  }

  // ❤️ TOGGLE WISHLIST
  Future<void> toggleWishlist(Map<String, dynamic> product) async {
    final ref = _firestore.collection("wishlist").doc(widget.userId);
    final doc = await ref.get();
    final data = doc.data();

    if (data != null &&
        data["items"] != null &&
        data["items"][product["id"]] != null) {
      await ref.update({
        "items.${product["id"]}": FieldValue.delete(),
      });
    } else {
      await ref.set({
        "items": {
          product["id"]: product,
        }
      }, SetOptions(merge: true));
    }
  }

  void onTabChange(int index) {
    setState(() => currentIndex = index);

    if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => WishlistScreen()));
    } else if (index == 2) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => CartScreen()));
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(userId: widget.userId),
        ),
      );
    }
  }

  Widget categoryItem(IconData icon, String title) {
    final isSelected = selectedCategory == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = title;
        });
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.green,
              size: 30,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        title: TextField(
          onChanged: (v) => setState(() => searchText = v),
          decoration: InputDecoration(
            hintText: "Search products...",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),

      body: StreamBuilder<List<String>>(
        stream: getWishlistIds(),
        builder: (context, wishSnap) {
          final wishlistIds = wishSnap.data ?? [];

          return StreamBuilder(
            stream: _firestore.collection("products").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = snapshot.data!.docs.where((doc) {
                final name = doc["name"].toString().toLowerCase();
                final category = doc["category"].toString();

                final matchSearch =
                name.contains(searchText.toLowerCase());
                final matchCategory =
                    selectedCategory == "All" ||
                        category == selectedCategory;

                return matchSearch && matchCategory;
              }).toList();

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // 🎯 BANNERS
                    SizedBox(
                      height: 140,
                      child: StreamBuilder(
                        stream:
                        _firestore.collection("banners").snapshots(),
                        builder: (context, bannerSnap) {
                          if (!bannerSnap.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final banners = bannerSnap.data!.docs;

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: banners.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.all(10),
                                width:
                                MediaQuery.of(context).size.width - 40,
                                child: ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(15),
                                  child: Image.network(
                                    banners[index]["image"],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // 📦 CATEGORIES
                    SizedBox(
                      height: 90,
                      child: ListView(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                        scrollDirection: Axis.horizontal,
                        children: [
                          categoryItem(Icons.apps, "All"),
                          categoryItem(Icons.local_grocery_store,
                              "Grocery"),
                          categoryItem(Icons.fastfood, "Snacks"),
                          categoryItem(Icons.local_drink, "Drinks"),
                          categoryItem(Icons.icecream, "Icecream"),
                          categoryItem(Icons.apple, "Fruits"),
                        ],
                      ),
                    ),

                    // 🛍 PRODUCTS
                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                      const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(10),
                      itemCount: products.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final isWish =
                        wishlistIds.contains(product.id);

                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius:
                            BorderRadius.circular(15),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 5)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                    const BorderRadius.only(
                                      topLeft:
                                      Radius.circular(15),
                                      topRight:
                                      Radius.circular(15),
                                    ),
                                    child: Image.network(
                                      product["image"],
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () =>
                                          toggleWishlist({
                                            "id": product.id,
                                            "name":
                                            product["name"],
                                            "price":
                                            product["price"],
                                            "image":
                                            product["image"],
                                          }),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                        Colors.white,
                                        child: Icon(
                                          Icons.favorite,
                                          color: isWish
                                              ? Colors.red
                                              : Colors.grey,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding:
                                const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Text(
                                      product["name"],
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight:
                                        FontWeight.bold,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "₹${product["price"]}",
                                      style:
                                      const TextStyle(
                                        color: Colors.green,
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width:
                                      double.infinity,
                                      child: ElevatedButton(
                                        style:
                                        ElevatedButton
                                            .styleFrom(
                                          backgroundColor:
                                          Colors.green,
                                          shape:
                                          RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius
                                                .circular(
                                                10),
                                          ),
                                        ),
                                        onPressed: () {
                                          addToCart({
                                            "id": product.id,
                                            "name": product[
                                            "name"],
                                            "price": product[
                                            "price"],
                                            "image": product[
                                            "image"],
                                          });
                                        },
                                        child: const Text(
                                            "Add to Cart"),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabChange,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Wishlist",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Cart",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}