const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Capfizz AI Server is running!');
});

app.listen(port, () => {
  console.log(`Capfizz AI server running at http://localhost:${port}`);
});
