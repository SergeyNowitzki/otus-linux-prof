const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
    res.send('Hello from Node.js!');
});

app.get('/node', (req, res) => {
    res.send('Hello from Node.js /node route!');
});

app.listen(port, () => {
    console.log(`Node.js app listening at http://localhost:${port}`);
});
