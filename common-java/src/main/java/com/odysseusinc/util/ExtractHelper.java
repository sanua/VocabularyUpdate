package com.odysseusinc.util;

import org.apache.commons.compress.archivers.ArchiveEntry;
import org.apache.commons.compress.archivers.ArchiveInputStream;
import org.apache.commons.compress.archivers.zip.ZipArchiveInputStream;
import org.apache.commons.compress.compressors.gzip.GzipUtils;
import org.apache.commons.lang3.StringUtils;

import java.io.*;
import java.nio.file.DirectoryStream;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.zip.GZIPInputStream;

/**
 * Created by Sanders on 6/26/2017.
 */
public class ExtractHelper {

    private static ExtractHelper instance = null;
    private final File workDir;

    private ExtractHelper(File workDir) {
        this.workDir = workDir;
    }

    public static ExtractHelper getInstance(File workDir) {
        if (instance == null)
            instance = new ExtractHelper(workDir);
        return instance;
    }

    private boolean fileNameContains(String fileName, List<String> maskList) {
        if (maskList == null || StringUtils.isBlank(fileName))
            return false;
        String fName = fileName.toLowerCase();
        for (String m: maskList) {
            if (fName.indexOf(m.toLowerCase()) >= 0)
                return true;
        }
        return false;
    }

    private boolean fileNameInList(String fileName, List<String> fileNames) {
        if (fileNames == null)
            return false;
        for (String f: fileNames) {
            if (f.toLowerCase().indexOf(fileName.toLowerCase()) >= 0)
                return true;
        }
        return false;
    }

    /**
     * Extract archives
     * @param is
     * @param extractFile
     * @param inputFileSize
     * @throws IOException
     */
    private void writeToFile(InputStream is, File extractFile, long inputFileSize) throws IOException {
        System.out.print(String.format("\t\t\tprocessing file: %s ", extractFile.getName()));
        byte[] buffer = new byte[8192];
        int count;
        OutputStream outputStream = null;
        long progress = 0, totalProgress = 0;
        byte percentProgress;
        byte decimalCount = 0;
        try {
            outputStream = new BufferedOutputStream(new FileOutputStream(extractFile));
            while ((count = is.read(buffer, 0, buffer.length)) != -1) {
                outputStream.write(buffer, 0, count);
                progress += count;
                totalProgress += count;
                percentProgress = Long.valueOf(Math.round(((double) progress / inputFileSize) * 100)).byteValue();
                if (percentProgress / 10 > decimalCount) {
                    decimalCount ++;
                    System.out.print(".");
                }
            }
            outputStream.flush();
        } finally {
            if (outputStream != null)
                outputStream.close();
        }
        float displaySize;
        String sizeUnit;
        if (totalProgress < 1024) {
            sizeUnit = "B";
            displaySize = Double.valueOf(totalProgress).floatValue();
        } else if ((totalProgress / 1024) < 1024) {
            sizeUnit = "KB";
            displaySize = Double.valueOf((double)(totalProgress / 1024)).floatValue();
        } else if ((totalProgress / 1024 / 1024) < 1024) {
            sizeUnit = "MB";
            displaySize = Double.valueOf((double)(totalProgress / 1024 / 1024)).floatValue();
        } else {
            sizeUnit = "GB";
            displaySize = Double.valueOf((double)(totalProgress / 1024 / 1024 / 1024)).floatValue();
        }
        System.out.println(String.format(" %.0f %s is done", displaySize, sizeUnit));
    }

    private void proxyWriteToFile(InputStream is, File extractFile, long inputFileSize, List<String> checkedFileNames) throws IOException {
        if (checkedFileNames == null || checkedFileNames.isEmpty()) {
            writeToFile(is, extractFile, inputFileSize);
        } else {
            String fileName = extractFile.getName();
            if (fileNameContains(fileName, checkedFileNames)) {
                writeToFile(is, extractFile, inputFileSize);
            }
        }
    }

    public <I extends InputStream> boolean extractAction(I archiveInputStream, File archiveFile, File destPath, List<String> checkedFileNames) throws IOException {
        System.out.println(String.format("\t\tExtracting file: %s to the: %s", archiveFile.getPath(), destPath.getPath()));
        try {
            File fileDir;
            if (archiveInputStream instanceof ArchiveInputStream) {
                ArchiveInputStream ais = (ArchiveInputStream) archiveInputStream;
                ArchiveEntry entry = ais.getNextEntry();
                while (entry != null) {
                    if (entry.isDirectory()) {
                        fileDir = new File(destPath, entry.getName());
                        fileDir.mkdirs();
                    } else {
                        fileDir = new File(destPath, entry.getName());
                        proxyWriteToFile(archiveInputStream, fileDir, entry.getSize(), checkedFileNames);
                    }
                    entry = ais.getNextEntry();
                }
            } else {
                String fileName = GzipUtils.getUncompressedFilename(archiveFile.getName());
                fileDir = new File(destPath, fileName);
                proxyWriteToFile(archiveInputStream, fileDir, archiveFile.length(), checkedFileNames);
            }
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            if (archiveInputStream != null)
                try {
                    archiveInputStream.close();
                } catch (IOException ioe) {}
        }
        return true;
    }

    public boolean extractArchive(File archiveFile, File destPath, List<String> checkedFileNames) {
        if (archiveFile == null || !archiveFile.exists() || !destPath.exists())
            return false;

        boolean result = false;
        InputStream archiveInputStream = null;
        try {
            switch (archiveFile.getName().substring(archiveFile.getName().lastIndexOf(".")+ 1)) {
                case "nlm":
                case "zip":
                    archiveInputStream = new ZipArchiveInputStream(
                            new BufferedInputStream(new FileInputStream(archiveFile))
                    );
                    result = extractAction(archiveInputStream, archiveFile, destPath, checkedFileNames);
                    break;
                case "gz":
                    if (true) {
                        archiveInputStream = new GZIPInputStream(new BufferedInputStream(new FileInputStream(archiveFile)));
                        result = extractAction(archiveInputStream, archiveFile, destPath, checkedFileNames);
                    }
                    break;
            }
        } catch (IOException ioe) {
            ioe.printStackTrace();
        } finally {
            if (archiveInputStream != null)
                try {
                    archiveInputStream.close();
                } catch (IOException e) {}
        }
        return result;
    }

    public void extract(File targetDir, List<String> checkedFileNames) throws IOException {
        extract(targetDir, targetDir, checkedFileNames, null);
    }

    public void extract(File targetDir, File workDir, List<String> checkedFileNames, List<String> processedFileNames) throws IOException {
        System.out.println(String.format("\nExtracting is started:\n\tworkDir: %s,\n\tprocessedFileNames: %s,\n\tcheckedFileNames: %s", workDir.getPath(), processedFileNames, checkedFileNames));

        List<String> newProcessedFileNames = new ArrayList<>();
        DirectoryStream<Path> stream = null;
        try {
            stream = java.nio.file.Files.newDirectoryStream(Paths.get(workDir.getPath()));
            for (Path path: stream) {
                if (path.toFile().isDirectory())
                    extract(targetDir, path.toFile(), checkedFileNames, processedFileNames);
                else {
                    String fName = path.getFileName().toString().toLowerCase();
                    if ((fName.endsWith(".zip") || fName.endsWith(".gz") || fName.endsWith(".nlm"))
                            && !fileNameInList(fName, processedFileNames) && fileNameContains(fName, checkedFileNames)) {
                        newProcessedFileNames.add(path.toAbsolutePath().toString());
                    }
                }
            }
        } finally {
            if (stream != null)
                stream.close();
        }

        // Exist when there is no files to extracting
        if (newProcessedFileNames.isEmpty()) {
            System.out.println("Nothing to extract");
            return;
        }

        System.out.println("\tFound files to extract:");
        for (String filename: newProcessedFileNames) {
            System.out.println(String.format("\n\t\t%s", filename));
            List<String> evaluatedCheckedFileNames = Collections.emptyList();
            if (processedFileNames != null && !processedFileNames.isEmpty()) {
                evaluatedCheckedFileNames = checkedFileNames;
            }
            if (!extractArchive(Paths.get(filename).toFile(), targetDir, evaluatedCheckedFileNames)) {
                System.out.println(String.format("\t\tCannot extract file: %s", filename));
            }
        }
        System.out.println("Extracting is done");

        /**
         * Add already processed archive to newly found.
         * That's need to avoid processed the same files twice
         */
        if (processedFileNames != null)
            newProcessedFileNames.addAll(processedFileNames);

        // Extract files
        extract(targetDir, targetDir, checkedFileNames, newProcessedFileNames);
    }

}
