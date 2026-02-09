import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';

import 'components/wallet_balance_card.dart';
import 'components/wallet_history_card.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wallet"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                sliver: SliverToBoxAdapter(
                  child: WalletBalanceCard(
                    balance: 384.90,
                    onTabChargeBalance: () {},
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: defaultPadding / 2),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    "Wallet history",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(top: defaultPadding),
                    child: WalletHistoryCard(
                      isReturn: index == 1,
                      date: "JUN 12, 2020",
                      amount: 10707, // 129 * 83
                      products: [
                        ProductModel(
                          image: productDemoImg1,
                          title: "Diamond Engagement Ring",
                          brandName: "Rituals",
                          description: "Beautiful diamond engagement ring",
                          category: "Jewelry",
                          price: 44820, // 540 * 83
                          priceAfetDiscount: 34860, // 420 * 83
                          dicountpercent: 20,
                          stockQuantity: 10,
                          maxOrderQuantity: 2,
                          isOutOfStock: false,
                          images: [productDemoImg1],
                        ),
                        ProductModel(
                          image: productDemoImg4,
                          title: "Gold Tennis Bracelet",
                          brandName: "Rituals",
                          description: "Elegant gold tennis bracelet",
                          category: "Jewelry",
                          price: 66400, // 800 * 83
                          stockQuantity: 5,
                          maxOrderQuantity: 1,
                          isOutOfStock: false,
                          images: [productDemoImg4],
                        ),
                      ],
                    ),
                  ),
                  childCount: 4,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
