/*
 * Thumbnail.java (requires Java 1.2+)
 */
package com.purplehillsbooks.photegrity;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.purplehillsbooks.json.JSONException;

@SuppressWarnings("serial")
public class Thumb extends javax.servlet.http.HttpServlet {

    // there seems to be memory problems with the image handling library
    // so lets synchronize to make sure only one of these are running at a time
    public static void shrinkFile(ImageInfo ii) throws Exception {
        File cacheDir = ii.getFolderPath();
        String fileName = ii.fileName;
        if (fileName.indexOf(".-.") > 0) {
            // don't shrink the backup files.
            // ignore files with dot hyphen dot in the name.
            return;
        }

        File originalFile = new File(cacheDir, fileName);
        File tempFile = new File(cacheDir, fileName + ".temp");
        System.out.println("Starting to SHRINK: "+originalFile.getAbsolutePath());


        // only one file operation on an image should run at a time
        synchronized (ii) {
            if (tempFile.exists()) {
                //maybe something left over from earlier?
                tempFile.delete();
            }
            FileOutputStream fos = new FileOutputStream(tempFile);
            Thumbnail.scalePhoto(originalFile, fos, 1200, 1024, 80);
            fos.close();

            // if new size is not at least 10% smaller then stick with
            // the old file.
            long originalSize = originalFile.length();
            if (originalSize < (tempFile.length() * 1.1)) {
                System.out.println("    fail SHRINKING: "+originalFile.getAbsolutePath());
                System.out.println("           oldfile: "+originalSize);
                System.out.println("      newfile size: "+tempFile.length());
                tempFile.delete();
                return;
            }

            // there appears to be a bug which creates blank shrunken files, which are
            // about 12K in size. That is too small to be a real photo, so reject the
            // shrink on this basis.
            if (tempFile.length() < 15000) {
                tempFile.delete();
                return;
            }

            originalFile.delete(); //go ahead and get rid of it..

            renameFile(tempFile, originalFile, "rename the temp file to the original file name");

            ii.actuallyExists();
            System.out.println("    done SHRINKING: "+originalFile.getAbsolutePath());
        }
    }

    public static void renameFile(File file, File newName, String context) throws Exception {
        // I don't like this code, but it seems that sometimes the rename fails
        // and it does not tell the reason. If I run the code again it works.
        // This code retries three times, separated by one second.
        if (!file.renameTo(newName)) {
            Thread.sleep(1000);
            if (!file.renameTo(newName)) {
                Thread.sleep(1000);
                if (!file.renameTo(newName)) {
                    throw new JSONException("oops, failed three times to {0}: {1}", context, newName);
                }
            }
        }
    }

    public static void genThumbNail(File thumbFile, File fullFile, int thumbSize) throws Exception {
        if (thumbFile.exists()) {
            if (thumbFile.length()>900) {
                return;
            }
        }
        if (!fullFile.exists()) {
            throw new JSONException("Error, attempting to make a thumbnail from a file that does not exist!: {0}", fullFile);
        }

        // only one file operation run at a time
        synchronized (Thumb.class) {

            // note, must check again because it might have been generated while
            // waiting for the lock!
            if (thumbFile.exists()) {
                if (thumbFile.length()>900) {
                    return;
                }
                thumbFile.delete();
            }

            // assure that the place is there to save to.
            thumbFile.getParentFile().mkdirs();

            Thumbnail.makeSquareFile(fullFile, thumbFile, thumbSize, 50);

            if (!thumbFile.exists()) {
                throw new JSONException("Hey, just created file and does not exist: {0}",thumbFile);
            }
            if (thumbFile.length() < 1000) {
                //something went wrong, get rid of garbage
                thumbFile.delete();
            }
        }

        if (!thumbFile.exists()) {
            throw new JSONException("Hey, failed to make thumb: {0}, from file: {1}", thumbFile, fullFile);
        }


    }

    public static void streamFile(OutputStream out, File file) throws Exception {
        FileInputStream fis = new FileInputStream(file);

        byte[] buf = new byte[2048];

        int amtRead = fis.read(buf);
        while (amtRead > 0) {
            out.write(buf, 0, amtRead);
            amtRead = fis.read(buf);
        }
        fis.close();
        out.flush();
    }

    public void doGet(HttpServletRequest req, HttpServletResponse resp) {
        OutputStream out = null;
        try {
            out = resp.getOutputStream();
            resp.setContentType("image/jpeg");
            req.setCharacterEncoding("UTF-8");

            String pathInfo = req.getPathInfo();
            String[] pathParts = UtilityMethods.splitOnDelimiter(pathInfo, '/');

            //pathParts[1] is the thumb size assume equal to 100

            String disk = pathParts[2];

            int filePart = pathParts.length - 1;
            String fileName = pathParts[filePart];

            StringBuffer path = new StringBuffer();
            for (int i = 3; i < filePart; i++) {
                path.append(pathParts[i]);
                path.append("/");
            }
            String relativePath = path.toString();

            DiskMgr dm = DiskMgr.getDiskMgr(disk);

            File thumbFile = new File(DiskMgr.thumbPath,"100/"+dm.diskName+"/"+relativePath+fileName);
            File fullFile = new File(dm.mainFolder,relativePath+fileName);

            if (!thumbFile.exists()) {
                genThumbNail(thumbFile, fullFile, 100);
            }
            streamFile(out, thumbFile);

        }
        catch (Exception e) {
            try {
                resp.setContentType("text/html");
                if (out == null) {
                    out = resp.getOutputStream();
                }
                Writer w = new OutputStreamWriter(out);
                w.write("<html><body><ul><li>Thumbnail Exception: ");
                w.write(UtilityMethods.getErrorString(e));
                w.write("</ul></body></html>");
                w.flush();
            }
            catch (Exception eeeee) {
                // nothing we can do here...
            }
        }
    }
}
