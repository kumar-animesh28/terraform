const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.send('<h1>Hello from Express Frontend</h1><p>Go to <a href="/api/hello">/api/hello</a> for backend response</p>');
});

app.listen(3000, () => console.log("Express running on port 3000"));
