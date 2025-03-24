const express = require('express');
const cors = require('cors');
const app = express();
const port = 5000;

app.use(cors());
app.use(express.json());

// Sample product data
const products = [
  {
    id: 1,
    name: "Premium Dog Food",
    description: "Nutritionally complete dry food for adult dogs",
    price: 29.99,
    category: "food",
    image: "https://images.unsplash.com/photo-1589924691995-400dc9ecc119?q=80&w=2070",
    rating: 4.8,
    stock: 50
  },
  {
    id: 2,
    name: "Cat Scratching Post",
    description: "Durable sisal scratching post with toy",
    price: 24.99,
    category: "accessories",
    image: "https://images.unsplash.com/photo-1545249390-6bdfa286032f?q=80&w=2034",
    rating: 4.5,
    stock: 30
  },
  {
    id: 3,
    name: "Aquarium Filter",
    description: "3-stage filtration system for clear water",
    price: 34.99,
    category: "equipment",
    image: "https://images.unsplash.com/photo-1522069169874-c58ec4b76be5?q=80&w=2012",
    rating: 4.2,
    stock: 15
  },
  {
    id: 4,
    name: "Bird Cage",
    description: "Spacious cage with multiple perches",
    price: 79.99,
    category: "housing",
    image: "https://images.unsplash.com/photo-1520808663317-647b476a81b9?q=80&w=2073",
    rating: 4.6,
    stock: 10
  },
  {
    id: 5,
    name: "Small Animal Bedding",
    description: "Soft, absorbent bedding for small pets",
    price: 12.99,
    category: "supplies",
    image: "https://images.unsplash.com/photo-1548767797-d8c844163c4c?q=80&w=2071",
    rating: 4.4,
    stock: 45
  },
  {
    id: 6,
    name: "Dog Collar",
    description: "Adjustable nylon collar with reflective strip",
    price: 14.99,
    category: "accessories",
    image: "https://images.unsplash.com/photo-1567612529009-afe25068d59e?q=80&w=2070",
    rating: 4.7,
    stock: 60
  }
];

// Categories collection
const categories = [
  { id: 1, name: "food", displayName: "Pet Food" },
  { id: 2, name: "accessories", displayName: "Accessories" },
  { id: 3, name: "equipment", displayName: "Equipment" },
  { id: 4, name: "housing", displayName: "Housing" },
  { id: 5, name: "supplies", displayName: "Supplies" }
];

// API endpoints
app.get('/', (req, res) => {
  res.send('PetShop API is running');
});

app.get('/api/products', (req, res) => {
  res.json(products);
});

app.get('/api/products/:id', (req, res) => {
  const product = products.find(p => p.id === parseInt(req.params.id));
  if (!product) return res.status(404).json({ message: 'Product not found' });
  res.json(product);
});

app.get('/api/categories', (req, res) => {
  res.json(categories);
});

app.get('/api/products/category/:categoryName', (req, res) => {
  const categoryProducts = products.filter(p => p.category === req.params.categoryName);
  res.json(categoryProducts);
});

// Mock cart functionality
let cart = [];

// Enhanced cart endpoints with logging
app.get('/api/cart', (req, res) => {
  console.log('GET /api/cart - Current cart items:', cart.length);
  res.json(cart);
});

app.post('/api/cart', (req, res) => {
  const { productId, quantity } = req.body;
  console.log(`POST /api/cart - Adding product ID: ${productId}, quantity: ${quantity}`);
  
  const product = products.find(p => p.id === parseInt(productId));
  
  if (!product) {
    console.log(`Product ID ${productId} not found`);
    return res.status(404).json({ message: 'Product not found' });
  }
  
  const cartItem = {
    id: Date.now(),
    productId,
    name: product.name,
    price: product.price,
    quantity: quantity || 1,
    image: product.image
  };
  
  cart.push(cartItem);
  console.log(`Added to cart - Item ID: ${cartItem.id}, Name: ${cartItem.name}`);
  console.log(`Current cart now has ${cart.length} items`);
  
  res.status(201).json(cartItem);
});

app.delete('/api/cart/:id', (req, res) => {
  const itemId = parseInt(req.params.id);
  console.log(`DELETE /api/cart/${itemId} - Removing item from cart`);
  
  const initialLength = cart.length;
  cart = cart.filter(item => item.id !== itemId);
  
  if (cart.length === initialLength) {
    console.log(`Item ID ${itemId} not found in cart`);
    return res.status(404).json({ message: 'Cart item not found' });
  }
  
  console.log(`Removed item ID: ${itemId}. Cart now has ${cart.length} items`);
  res.json({ message: 'Item removed from cart' });
});

app.listen(port, () => {
  console.log(`PetShop API server running at http://localhost:${port}`);
});
