// Test script to check MERN backend authentication
const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY2ZjdkMGU0NWJiYjEzZTA0OGI5MmRjNyIsInJvbGUiOiJhZG1pbiIsImVtYWlsIjoiYWRtaW40QGV4YW1wbGUuY29tIiwiaWF0IjoxNzI1NzAwMTU0LCJleHAiOjE3MjY5MDk3NTR9.g8qL6TwrjuTpKU3f-dtyntGRHX2c2s';

// Test 1: Check token with GET endpoint
fetch('https://backendd-ankp.onrender.com/api/v1/admin/users', {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
})
.then(response => {
  console.log('GET /admin/users - Status:', response.status);
  return response.text();
})
.then(data => {
  console.log('GET /admin/users - Response:', data);
})
.catch(error => {
  console.error('GET /admin/users - Error:', error);
});

// Test 2: Try product creation
const productData = {
  name: "Test Product",
  description: "Test Description",
  category: "Clothing",
  price: 100,
  stock: 50,
  images: []
};

fetch('https://backendd-ankp.onrender.com/api/v1/admin/product', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(productData)
})
.then(response => {
  console.log('POST /admin/product - Status:', response.status);
  return response.text();
})
.then(data => {
  console.log('POST /admin/product - Response:', data);
})
.catch(error => {
  console.error('POST /admin/product - Error:', error);
});
