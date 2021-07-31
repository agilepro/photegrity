package com.purplehillsbooks.photegrity;

import org.bson.Document;

import com.mongodb.client.FindIterable;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoCursor;
import com.mongodb.client.MongoDatabase;
import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONObject;

/**
 * Isolate the arcate Mongo specific classes here if possible
 */
public class MongoDB {

    public final String uri = "mongodb://localhost:27017";
    MongoClient mongoClient;
    MongoDatabase db;
    MongoCollection<org.bson.Document> pospatdb;
    
    public MongoDB() {
        mongoClient = MongoClients.create(uri);
        db = mongoClient.getDatabase("photo");
        pospatdb = db.getCollection("pospat");
    }
    
    /**
     * don't try to use this after closing
     */
    public void close() {
        mongoClient.close();
    }
    
    /**
     * simple default query that gets all the records up to a limit
     * probably only useful for testing/debugging
     */
    public JSONArray findAllRecords(int limit) throws Exception {
        FindIterable<Document> resultSet = pospatdb.find();
        MongoCursor<Document> cursor = resultSet.iterator();
        
        JSONArray ja = new JSONArray();
        int count = 0;
        while (count++ < limit && cursor.hasNext()) {
            Document d = cursor.next();
            
            JSONObject jo = new JSONObject(d.toJson());
            ja.put(jo);
        }
        return ja;
    }
    
    public void updatePosPat(PosPat pp) throws Exception {
        JSONObject jo = pp.getFullMongoDoc();
        String symbol = pp.getSymbol();
        
        
        JSONObject filter = new JSONObject();
        filter.put("symbol", symbol);
        
        pospatdb.deleteMany(Document.parse(filter.toString(2)));
        

        pospatdb.insertOne(Document.parse(jo.toString(2)));
        
    }
    
    
}
