mongo test1 --eval="db.test1.save({ Name: \"Bob\", Age: 12 })" && mongo test1 --eval="db.test1.find().forEach(printjson)"
