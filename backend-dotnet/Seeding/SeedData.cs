using System.Text.Json;
using FarmFresh.Api.Data;
using FarmFresh.Api.Models;

namespace FarmFresh.Api.Seeding;

// Port of backend/prisma/seed.ts. Runs once on a fresh database (skips if data
// already exists, so restarts don't wipe real orders/customers).
public static class SeedData
{
    public static void Run(AppDbContext db)
    {
        if (db.Categories.Any()) return;   // already seeded

        var categories = new (string slug, string name, string emoji)[]
        {
            ("rice", "Rice", "🍚"),
            ("dal-pulses", "Dal & Pulses", "🫘"),
            ("wheat-flour", "Wheat & Flour", "🌾"),
            ("oils-ghee", "Oils & Ghee", "🛢️"),
            ("spices", "Spices", "🌶️"),
            ("millets", "Millets", "🌱"),
            ("tea-coffee", "Tea & Coffee", "☕"),
            ("sugar-jaggery", "Sugar & Jaggery", "🍯"),
        };
        for (var i = 0; i < categories.Length; i++)
            db.Categories.Add(new Category { Slug = categories[i].slug, Name = categories[i].name, Emoji = categories[i].emoji, SortOrder = i });

        var toorNutrition = JsonSerializer.Serialize(new Dictionary<string, string>
        {
            ["Protein"] = "22 g", ["Carbohydrates"] = "63 g", ["Fibre"] = "15 g", ["Energy"] = "343 kcal",
        });

        // id, name, source, packedDate, price, marketPrice, grade, tags, categorySlug, harvestMonth, packSize, nutrition
        var products = new[]
        {
            new Product { Id = "toor-dal", Name = "Premium Toor Dal", Source = "Vidarbha, MH", PackedDate = "10 Jun", Price = 160, MarketPrice = 198, Grade = "Premium A", Tags = "best,premium", CategorySlug = "dal-pulses", HarvestMonth = "March 2026", PackSize = "1 kg", Nutrition = toorNutrition },
            new Product { Id = "wheat-flour", Name = "Farm Wheat Flour", Source = "Own farm, Nashik", PackedDate = "12 Jun", Price = 255, MarketPrice = 320, Grade = "Chakki Fresh", Tags = "best,fresh", CategorySlug = "wheat-flour", PackSize = "10 kg" },
            new Product { Id = "basmati-rice", Name = "Premium Basmati Rice", Source = "Haryana mills", PackedDate = "08 Jun", Price = 540, MarketPrice = 640, Grade = "Aged 1yr", Tags = "best,premium", CategorySlug = "rice", PackSize = "5 kg" },
            new Product { Id = "groundnut-oil", Name = "Groundnut Oil", Source = "Saurashtra", PackedDate = "05 Jun", Price = 1150, MarketPrice = 1320, Grade = "Cold pressed", Tags = "premium", CategorySlug = "oils-ghee", PackSize = "5 L" },
            new Product { Id = "jaggery-powder", Name = "Jaggery Powder", Source = "Kolhapur", PackedDate = "11 Jun", Price = 95, MarketPrice = 120, Grade = "Chemical-free", Tags = "fresh", CategorySlug = "sugar-jaggery", PackSize = "1 kg" },
            new Product { Id = "chilli-powder", Name = "Red Chilli Powder", Source = "Guntur", PackedDate = "09 Jun", Price = 240, MarketPrice = 295, Grade = "Premium", Tags = "premium", CategorySlug = "spices", PackSize = "500 g" },
            new Product { Id = "moong-dal", Name = "Moong Dal", Source = "Rajasthan", PackedDate = "10 Jun", Price = 140, MarketPrice = 175, Grade = "Premium A", Tags = "best", CategorySlug = "dal-pulses", PackSize = "1 kg" },
            new Product { Id = "ragi-flour", Name = "Ragi Flour", Source = "Karnataka", PackedDate = "07 Jun", Price = 88, MarketPrice = 110, Grade = "Stone ground", Tags = "fresh", CategorySlug = "millets", PackSize = "1 kg" },
        };
        // chilli = out of stock, jaggery = low, to demo states.
        var stockMap = new Dictionary<string, int>
        {
            ["toor-dal"] = 40, ["wheat-flour"] = 30, ["basmati-rice"] = 25, ["groundnut-oil"] = 18,
            ["jaggery-powder"] = 3, ["chilli-powder"] = 0, ["moong-dal"] = 35, ["ragi-flour"] = 22,
        };
        foreach (var p in products)
        {
            p.ImageUrl = $"/uploads/{p.Id}.png";
            p.Stock = stockMap.TryGetValue(p.Id, out var s) ? s : 20;
            db.Products.Add(p);
        }

        // Pack-size variants: label, price, marketPrice, stock.
        var variants = new Dictionary<string, (string label, int price, int market, int stock)[]>
        {
            ["toor-dal"] = new[] { ("500 g", 85, 105, 30), ("1 kg", 160, 198, 40), ("2 kg", 300, 380, 15) },
            ["moong-dal"] = new[] { ("500 g", 75, 95, 20), ("1 kg", 140, 175, 35) },
            ["basmati-rice"] = new[] { ("1 kg", 120, 145, 20), ("5 kg", 540, 640, 25), ("10 kg", 1040, 1260, 8) },
            ["wheat-flour"] = new[] { ("5 kg", 135, 170, 30), ("10 kg", 255, 320, 30) },
        };
        foreach (var (pid, vs) in variants)
            for (var i = 0; i < vs.Length; i++)
                db.ProductVariants.Add(new ProductVariant { ProductId = pid, Label = vs[i].label, Price = vs[i].price, MarketPrice = vs[i].market, Stock = vs[i].stock, SortOrder = i });

        db.Reviews.Add(new Review { ProductId = "toor-dal", Initials = "PM", Author = "Priya M.", Area = "Powai", Rating = 5, Text = "Cooks soft, clean dal. Better than store brand." });
        db.Reviews.Add(new Review { ProductId = "toor-dal", Initials = "RS", Author = "Rohit S.", Area = "Vashi", Rating = 4, Text = "Fair price and fresh packing date." });

        var combos = new[]
        {
            new ComboPack { Id = "bachelor", Name = "Bachelor Pack", Type = "family", Price = 999, Size = "1 person", Duration = "2–3 weeks", Items = "Rice 2kg, Atta 2kg, Dal 1kg, Oil 1L, Sugar 1kg, Tea 250g", SavingsNote = "Save ~₹120*" },
            new ComboPack { Id = "couple", Name = "Couple Pack", Type = "family", Price = 2499, Size = "2 people", Duration = "1 month", Items = "Rice 5kg, Atta 5kg, Dals 3kg, Oil 2L, Sugar 2kg, Spices set", SavingsNote = "Save ~₹320*" },
            new ComboPack { Id = "small-family", Name = "Small Family Pack", Type = "family", Price = 4999, Size = "3–4 people", Duration = "1 month", Items = "Rice 10kg, Atta 10kg, Dals 5kg, Oil 5L, Sugar 3kg, Spices, Tea", SavingsNote = "Save ~₹600*" },
            new ComboPack { Id = "medium-family", Name = "Medium Family Pack", Type = "family", Price = 7999, Size = "5–6 people", Duration = "1 month", Items = "Rice 15kg, Atta 15kg, Dals 8kg, Oil 8L, Sugar 5kg, Spices, Tea, Jaggery", SavingsNote = "Save ~₹900*" },
            new ComboPack { Id = "large-family", Name = "Large Family Pack", Type = "family", Price = 11999, Size = "7+ / joint", Duration = "1 month", Items = "Rice 25kg, Atta 25kg, Dals 12kg, Oil 12L, Sugar 8kg, Full spice set", SavingsNote = "Save ~₹1,400*" },
            new ComboPack { Id = "fitness", Name = "Fitness Pack", Type = "health", Price = 2999, Size = "High energy", Duration = "1 month", Items = "Oats, Brown rice, Millets, Moong, Peanut, Honey", SavingsNote = "Save ~₹350*" },
            new ComboPack { Id = "diabetic", Name = "Diabetic Friendly Pack", Type = "health", Price = 3299, Size = "Low GI", Duration = "1 month", Items = "Ragi, Jowar, Bajra, Brown rice, Chana, Methi seeds", SavingsNote = "Save ~₹400*" },
            new ComboPack { Id = "weight-loss", Name = "Weight Loss Pack", Type = "health", Price = 2799, Size = "Low cal", Duration = "1 month", Items = "Millets, Oats, Moong, Quinoa, Flax, Green tea", SavingsNote = "Save ~₹300*" },
            new ComboPack { Id = "high-protein", Name = "High Protein Vegetarian Pack", Type = "health", Price = 3499, Size = "Protein+", Duration = "1 month", Items = "Soya, Rajma, Chana, Moong, Peanut, Sprouts mix", SavingsNote = "Save ~₹450*" },
            new ComboPack { Id = "ganpati", Name = "Ganpati Pack", Type = "festival", Price = 1999, Size = "Pooja + prasad", Duration = "Festival", Items = "Rice, Rava, Jaggery, Ghee, Dry fruits, Coconut", SavingsNote = "Save ~₹250*" },
            new ComboPack { Id = "diwali", Name = "Diwali Pack", Type = "festival", Price = 2999, Size = "Sweets + faral", Duration = "Festival", Items = "Besan, Maida, Rava, Sugar, Ghee, Dry fruits, Oil", SavingsNote = "Save ~₹380*" },
            new ComboPack { Id = "gudi-padwa", Name = "Gudi Padwa Pack", Type = "festival", Price = 1799, Size = "New year", Duration = "Festival", Items = "Rice, Jaggery, Neem, Rava, Ghee, Dry fruits", SavingsNote = "Save ~₹220*" },
            new ComboPack { Id = "upvas", Name = "Upvas Pack", Type = "festival", Price = 1499, Size = "Vrat items", Duration = "Fasting", Items = "Sabudana, Rajgira, Singhara flour, Peanut, Rock salt", SavingsNote = "Save ~₹180*" },
        };
        db.ComboPacks.AddRange(combos);

        db.SubscriptionPlans.AddRange(
            new SubscriptionPlan { Id = "monthly-essentials", Name = "Monthly Essentials Plan", Description = "Core grains, dal, oil & sugar each month", PriceLabel = "from ₹2,499/mo*" },
            new SubscriptionPlan { Id = "family-savings", Name = "Family Savings Plan", Description = "Bigger basket, best combined savings", PriceLabel = "from ₹4,999/mo*" },
            new SubscriptionPlan { Id = "premium-quality", Name = "Premium Quality Plan", Description = "Top-grade own-label premium range", PriceLabel = "from ₹5,999/mo*" },
            new SubscriptionPlan { Id = "custom-kirana", Name = "Custom Kirana Plan", Description = "Built from your Auto Kirana List", PriceLabel = "budget-based*" });

        var kiranaLines = new (string name, string qty, string price)[]
        {
            ("Rice", "10 kg", "₹540"), ("Wheat Flour", "15 kg", "₹765"), ("Toor Dal", "3 kg", "₹480"),
            ("Chana Dal", "2 kg", "₹260"), ("Sugar", "2 kg", "₹110"), ("Tea", "1 kg", "₹450"), ("Oil", "5 L", "₹1,150"),
        };
        for (var i = 0; i < kiranaLines.Length; i++)
            db.BasketLines.Add(new BasketLine { List = "kirana", Name = kiranaLines[i].name, Quantity = kiranaLines[i].qty, PriceLabel = kiranaLines[i].price, SortOrder = i });

        var repeatLines = new (string name, string qty, string price)[]
        {
            ("Premium Basmati Rice", "5 kg", "₹540"), ("Farm Wheat Flour", "10 kg", "₹510"), ("Toor Dal", "3 kg", "₹480"),
            ("Moong Dal", "2 kg", "₹280"), ("Groundnut Oil", "5 L", "₹1,150"), ("Sugar", "2 kg", "₹110"),
            ("Tea", "500 g", "₹225"), ("Red Chilli Powder", "500 g", "₹120"), ("Jaggery Powder", "1 kg", "₹95"),
        };
        for (var i = 0; i < repeatLines.Length; i++)
            db.BasketLines.Add(new BasketLine { List = "repeat", Name = repeatLines[i].name, Quantity = repeatLines[i].qty, PriceLabel = repeatLines[i].price, SortOrder = i });

        var slots = new[]
        {
            "Tomorrow · 8–11 AM", "Tomorrow · 12–3 PM", "Tomorrow · 5–8 PM", "Day after · 8–11 AM", "Day after · 5–8 PM",
        };
        for (var i = 0; i < slots.Length; i++)
            db.DeliverySlots.Add(new DeliverySlot { Label = slots[i], SortOrder = i });

        db.ServiceableAreas.AddRange(
            new ServiceableArea { Pincode = "400703", Area = "Vashi", City = "Navi Mumbai", EtaLabel = "Tomorrow by 11 AM" },
            new ServiceableArea { Pincode = "410210", Area = "Kharghar", City = "Navi Mumbai", EtaLabel = "Tomorrow by 1 PM" },
            new ServiceableArea { Pincode = "400076", Area = "Powai", City = "Mumbai", EtaLabel = "Next day" });

        db.DeliveryPartners.AddRange(
            new DeliveryPartner { Name = "Ravi K.", Phone = "9820011111" },
            new DeliveryPartner { Name = "Suresh M.", Phone = "9820022222" });

        db.Coupons.AddRange(
            new Coupon { Code = "FRESH50", Type = "flat", Value = 50, MinOrder = 500 },
            new Coupon { Code = "SAVE10", Type = "percent", Value = 10, MinOrder = 300, MaxDiscount = 150 });

        db.Banners.AddRange(
            new Banner { Title = "Monthly kirana, sorted", Subtitle = "Auto-build a full basket for your family", ActionType = "url", ActionValue = "/kirana", SortOrder = 0 },
            new Banner { Title = "Save with combo packs", Subtitle = "Family & festival packs at fixed prices", ActionType = "url", ActionValue = "/home/combos", SortOrder = 1 });

        db.SaveChanges();
        Console.WriteLine($"Seed complete: {categories.Length} categories, {products.Length} products, {combos.Length} combos.");
    }
}
