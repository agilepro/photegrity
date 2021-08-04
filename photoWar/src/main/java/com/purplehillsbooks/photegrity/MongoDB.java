package com.purplehillsbooks.photegrity;

import java.util.List;
import java.util.Vector;

import org.bson.Document;

import com.mongodb.client.FindIterable;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoCursor;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.result.DeleteResult;
import com.mongodb.client.result.InsertOneResult;
import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
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
    public JSONArray queryRecords(JSONObject query, int limit) throws Exception {
        Document dq = Document.parse(query.toString(0));
        FindIterable<Document> resultSet = pospatdb.find(dq);
        
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
    
    
    /**
     * This deletes all the pospat records that are associated with a particular disk
     */
    public void clearAllFromDisk(String diskName) throws Exception {
        //this should identify the existing pos pat record for deleting it if exists
        JSONObject filter = new JSONObject();
        filter.put("disk", diskName);
        pospatdb.deleteMany(Document.parse(filter.toString(2)));
    }
    public void clearAllFromDiskPath(String diskName, String path) throws Exception {
        //this should identify the existing pos pat record for deleting it if exists
        JSONObject filter = new JSONObject();
        filter.put("disk", diskName);
        filter.put("path", path);
        DeleteResult dr = pospatdb.deleteMany(Document.parse(filter.toString(0)));
        System.out.println("MONGO: removed "+dr.getDeletedCount()+" records disk=("+diskName+") path=("+path+") using "+filter.toString(0));
    }
    
    public void updatePosPat(PosPat pp) throws Exception {
        String symbol = pp.getSymbol();
        
        //this should identify the existing pos pat record for deleting it if exists
        JSONObject filter = new JSONObject();
        filter.put("symbol", symbol);
        DeleteResult dr = pospatdb.deleteOne(Document.parse(filter.toString(2)));
        System.out.println("MONGO: removed "+dr.getDeletedCount()+" records using "+filter.toString(0));
        
        //now add the new one for this symbol
        JSONObject jo = pp.getFullMongoDoc();
        InsertOneResult ior = pospatdb.insertOne(Document.parse(jo.toString(2)));
        System.out.println("MONGO: added ("+ior.wasAcknowledged()+") record using "+jo.toString(2));
        
    }
    public void createPosPatRecord(String symbol, List<ImageInfo> imagesForPP) throws Exception {
        
        //this should identify the existing pos pat record for deleting it if exists
        JSONObject filter = new JSONObject();
        filter.put("symbol", symbol);
        pospatdb.deleteOne(Document.parse(filter.toString(2)));
        
        PosPat pp = PosPat.getPosPatFromSymbol(symbol);
        JSONObject jo = pp.getFullMongoDoc(imagesForPP);
        pospatdb.insertOne(Document.parse(jo.toString(2)));
    }
    
    public JSONArray querySets(String query) throws Exception {
        System.out.println("MONGO: query for: "+query);
        try {

            if (query.length()<4) {
                throw new JSONException("query is too short, must be letter, an open paren, at least one value char, and a close paren");
            }
           

            if (query.charAt(1) != '(') {
                throw new JSONException("error with query, second character must be an open paren");
            }

            JSONObject mongoQuery = new JSONObject();
            
            // all conditions will be ANDED together:  (AND  q q q)
            JSONArray queryAndList = new JSONArray();


            int startPos = 0;
            while (startPos<query.length()) {
                char sel = query.charAt(startPos++);
                if (query.charAt(startPos) != '(') {
                    throw new JSONException("error with query, character "+startPos+" must be an open paren");
                }
                startPos++;
                int pos = query.indexOf(')', startPos);
                if (pos<0) {
                    throw new JSONException("Error, can not find the closing paren char after position {0}", startPos);
                }
                String val = query.substring(startPos, pos);
                JSONObject q = new JSONObject();
                switch (sel) {
                    case 'g':
                        q.put("tags", val.toLowerCase());
                        queryAndList.put(q);
                        break;
                    case 'p':
                        //pattern starts with this
                        q.put("pattern", val);
                        queryAndList.put(q);
                        break;
                    case 'b':
                        //pattern starts with this
                        JSONObject negp = q.requireJSONObject("pattern");
                        negp.put("$ne", val.toLowerCase());
                        queryAndList.put(q);
                        break;
                    case 'e':
                        //this is the exact match
                        q.put("pattern", val);
                        queryAndList.put(q);
                        break;
                    case 's':   
                        //pattern starts with
                        JSONObject regex = q.requireJSONObject("pattern");
                        regex.put("$regex", "^"+val);
                        queryAndList.put(q);
                        break;
                    case 'd':  
                        //exclude tag
                        JSONObject condition = q.requireJSONObject("tags");
                        condition.put("$ne", val.toLowerCase());
                        queryAndList.put(q);
                        break;
                    default:
                        throw new JSONException("secondary query elements must begin with a 'g' for tag, "
                            +"'d' for NOT tag, 'p' for pattern contains, 'b' for pattern not contains, "
                            +"'s' pattern starts,  or 'e' for pattern exact, 't' for duplicate size, "
                            +"'i' for index, and '!' for NOT index, 'n' for numeric range, 'u' for number of tags,"
                            +"'l' for larger-than size");
                }
                startPos = pos+1;
            }
            

            mongoQuery.put("$and", queryAndList);
            JSONArray res = queryRecords(mongoQuery, 100);

            System.out.println("MONGO: query found: "+res.length()+" records");
            return res;
        }
        catch(Exception e) {
            throw new JSONException("Error in queryImages({0})",e, query);
        }
    }
}
