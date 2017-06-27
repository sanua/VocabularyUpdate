package com.odysseusinc.convert;

import com.google.common.io.Files;
import com.odysseusinc.util.IllegalUpdateStateException;
import org.apache.commons.io.FileUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.poi.ss.usermodel.*;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.*;

/**
 * Created by Sanders on 5/26/2017.
 */
public class Xls2CsvHelper {

    public static final String CSV_FIELD_SEPARATOR = ";";

    private File convertPath;
    private static Xls2CsvHelper singleInstance;

    private Xls2CsvHelper() {
        this(null);
    }

    private Xls2CsvHelper(File convertPath) {
        if (convertPath == null || !convertPath.exists()) {
            this.convertPath = Files.createTempDir();
        } else
            this.convertPath = convertPath;
    }

    public static Xls2CsvHelper getXls2CsvHelper() {
        return getXls2CsvHelper(null);
    }

    public static Xls2CsvHelper getXls2CsvHelper(File convertPath) {
        if (singleInstance == null) {
            singleInstance = new Xls2CsvHelper(convertPath);
        }
        return singleInstance;
    }

    private String convertSheetByName(Workbook workbook) {
        return convertSheetByName(workbook, null, null);
    }

    private String normalizeString(String value) {
        String result = new String(value);
        // If empty - just return
        if (StringUtils.isBlank(value))
            return result;
        boolean doubleQuotesProcessed = false
        // Replace all number of double quotes by twice double quotes
        if (result.indexOf("\"") >= 0) {
            result = result.replaceAll("(\"{1,1})", "\"\"");
            doubleQuotesProcessed = true;
        }
        // Replace all double quotes by
        if (result.indexOf(CSV_FIELD_SEPARATOR) >= 0 || doubleQuotesProcessed) {
            result = String.format("\"%s\"", result);
        }
        // Replace all carriage return to space
        if (result.indexOf("\n") >= 0) {
            result = result.replaceAll("\n", " ");
        }
        // Replace all carriage return to space
        if (result.indexOf("\r") >= 0) {
            result = result.replaceAll("\r", " ");
        }
        // Replace the 'EN DASH' (U+2013) by the 'HYPHEN-MINUS' (U+002D)
        if (result.indexOf("\u2013") >= 0) {
            result = result.replaceAll("\u2013", "\u002D");
        }
        return result;
    }

    private String convertSheetByName(Workbook workbook, String name, String skipColumnsAfterName) {
        /**
         * Get Sheet by name of first sheet is name is not specified.
         */
        Sheet sheet = null;
        if (StringUtils.isNotBlank(name)) {
            for (int i = 0; i < workbook.getNumberOfSheets(); i++) {
                sheet = workbook.getSheetAt(i);
                if (sheet.getSheetName().equalsIgnoreCase(name)) {
                    break;
                }
            }
            if (sheet == null)
                throw new IllegalArgumentException(String.format("No Excel Sheet found for name: %s", name));
        } else
            sheet = workbook.getSheetAt(0);
        /**
         * Read data from cells
         */
        int skipColumnNumber = Integer.MAX_VALUE;
        StringBuffer data = new StringBuffer();
        for (int i = 0; i <= sheet.getLastRowNum(); i++) {
            Row row = sheet.getRow(i);
            boolean isCheckColumnsSkip = (i ==0 && StringUtils.isNotBlank(skipColumnsAfterName));
            if (row != null) {
                cell_loop:
                for (int j = 0; j < row.getLastCellNum(); j++) {
                    Cell cell = row.getCell(j);
                    if (cell == null) {
                        data.append(";");
                    } else {
                        cell.setCellType(Cell.CELL_TYPE_STRING);
                        String cellText = cell.toString().trim();
                        if (isCheckColumnsSkip  && cellText.equalsIgnoreCase(skipColumnsAfterName)) {
                            skipColumnNumber = j;
                        }
                        if (j <= skipColumnNumber) {
                            data.append(normalizeString(cellText));
                            if (j < skipColumnNumber && (j < row.getLastCellNum())) {
                                data.append(";");
                            }
                        } else
                            break cell_loop;
                    }
                }
                data.append('\n');
            }
        }
        return data.toString();
    }

    public void convertHcpcs(String inputFile, String outputFile) throws IllegalUpdateStateException, IOException {
        System.out.println("\n\tConversion of HCPCS data started");
        File f = new File(outputFile.substring(0, outputFile.lastIndexOf(File.separator) + 1));
        if (!f.exists()) {
            f.mkdir();
        } else {
            FileUtils.cleanDirectory(f);
        }
        /**
         * For storing data into CSV files
         */
        String data;
        FileOutputStream fos = null;
        try {
            fos = new FileOutputStream(outputFile);
            /**
             * Get the workbook object for XLS file
             */
            Workbook workbook = WorkbookFactory.create(new FileInputStream(inputFile));
            /**
             * Get data from default (first) sheet and save to file
             */
            data = convertSheetByName(workbook);
            fos.write(data.getBytes(StandardCharsets.UTF_8));
            fos.flush();
            System.out.println("\tConversion of HCPCS data done");
        } catch (Exception e) {
            e.printStackTrace();
            throw new IllegalUpdateStateException(e);
        } finally {
            try {
                if (fos != null)
                    fos.close();
            } catch (IOException ioe) {}
        }
    }

    public void convertLoinc(String inputFile, String destFolder, Map<String, String> sheetNameFilePathMap, Map<String, String> sheetNameSkiptColumnsAfterNameMap) throws IllegalUpdateStateException, IOException {
        System.out.println("\n\tConversion of LOINC data started");
        /**
         * Check if input Except file exists
         */
        File inputFileFullPath = new File(this.convertPath, inputFile);
        if (!inputFileFullPath.exists()) {
            throw new IOException(String.format("No input excel file found by name: %s", inputFileFullPath));
        }
        /**
         * Check output folder exists, if not - create it, otherwise - clean it
         */
        File outPath = new File(this.convertPath, destFolder);
        if (!outPath.exists()) {
            outPath.mkdir();
        } else {
            FileUtils.cleanDirectory(outPath);
        }

        String data;
        FileOutputStream fos = null;
        try {
            /**
             * Get the workbook object for XLS file
             */
            Workbook workbook = WorkbookFactory.create(new FileInputStream(inputFileFullPath));

            Iterator<Map.Entry<String, String>> it = sheetNameFilePathMap.entrySet().iterator();
            while (it.hasNext()) {
                Map.Entry<String, String> sheetPathEntry = it.next();
                String sheetName = sheetPathEntry.getKey();
                String fileName = sheetPathEntry.getValue();
                String skipColumnsAfterName = sheetNameSkiptColumnsAfterNameMap.get(sheetName);
                /**
                 * Get data from first sheet "ANSWERS" and save to file
                 */
                data = convertSheetByName(workbook, sheetName, skipColumnsAfterName);

                File savedFilePath = new File(outPath, fileName);
                sheetPathEntry.setValue(savedFilePath.getName());
                System.out.println(String.format("Conversion of Sheet '%s' done. Saved to: '%s'.", sheetName, savedFilePath.getPath()));
                fos = new FileOutputStream(savedFilePath);
                fos.write(data.getBytes(StandardCharsets.UTF_8));
                fos.flush();
            }
            System.out.println("\tConversion of LOINC data done");
        } catch (Exception e) {
            e.printStackTrace();
            throw new IllegalUpdateStateException(e);
        } finally {
            try {
                if (fos != null)
                    fos.close();
            } catch (IOException ioe) {}
        }
    }

    public String getNormalizedCsvFile(String filePath, String fieldSeparator) {
        File srcFile = new File(filePath);
        if (!srcFile.exists())
            return filePath;
        try {
            BufferedReader bufferedReader = new BufferedReader(new FileReader(srcFile));

            File tempFile = File.createTempFile(srcFile.getName(), "tmp");
            BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(tempFile));

            String stringLine;
            while ((stringLine = bufferedReader.readLine()) != null) {
                List<String> normalizedStringLineList = new ArrayList<>();
                List<String> stringLineList = Arrays.asList(stringLine.split(fieldSeparator));
                boolean needWrapsDoubleQuotes = false;
                for (String s: stringLineList) {
                    needWrapsDoubleQuotes = s.substring(0, 1).equalsIgnoreCase("\"") && s.substring(s.length()-1, s.length()).equalsIgnoreCase("\"")
                    s = StringUtils.stripEnd(StringUtils.stripStart(s, "\""), "\"");
                    if (needWrapsDoubleQuotes)
                        s = String.format("\"%s\"", s);
                    normalizedStringLineList.add(normalizeString(s));
                }

                String normalizedStringLine = String.join(fieldSeparator, normalizedStringLineList);
                bufferedWriter.write (normalizedStringLine + "\r\n");
                bufferedWriter.flush();
            }
            return tempFile.getPath();

        } catch (Exception e) {
            e.printStackTrace();
            return filePath;
        }
    }

    private static boolean fileHasExtension(String fileName, List<String> extensionList) {
        if (extensionList == null || StringUtils.isBlank(fileName))
            return false;
        String fName = fileName.toLowerCase();
        for (String ext: extensionList) {
            if (fName.endsWith(ext.toLowerCase()))
                return true;
        }
        return false;
    }

    public static List<File> getFilesByName(File folder, String nameTemplate, boolean strictSearch) throws IllegalUpdateStateException {
        return getFilesByName(folder, nameTemplate, Collections.EMPTY_LIST, strictSearch);
    }

    public static List<File> getFilesByName(File folder, String nameTemplate, String excludeExtension, boolean strictSearch) throws IllegalUpdateStateException {
        return getFilesByName(folder, nameTemplate, Arrays.asList(excludeExtension), strictSearch);
    }

    public static List<File> getFilesByName(File folder, String nameTemplate, List<String> excludeExtensionList, boolean strictSearch) throws IllegalUpdateStateException {
        File[] matchedFiles = folder.listFiles(new FilenameFilter() {
            @Override
            public boolean accept(File dir, String name) {
                return name.toLowerCase().indexOf(nameTemplate.trim().toLowerCase()) >= 0 &&
                        !fileHasExtension(name, excludeExtensionList);
            }
        });
        List<File> foundFiles = Arrays.asList(matchedFiles);

        if (strictSearch) {
            if (foundFiles.isEmpty())
                throw new IllegalUpdateStateException(String.format("No file found by name: %s", nameTemplate));
            else if (foundFiles.size() > 1)
                throw new IllegalUpdateStateException(String.format("More than one files found by name: %s", nameTemplate));
        }
        return foundFiles;
    }

    public static String copy(String from, String to) throws IOException {
        Path copyFrom = Paths.get(from);
        Path copyTo = Paths.get(to);
        Path targetFile = java.nio.file.Files.copy(copyFrom, copyTo, StandardCopyOption.REPLACE_EXISTING);
        return targetFile.normalize().toString();
    }

    public static void main(String[] args) throws IllegalUpdateStateException, IOException {
        System.out.println("*** Data convertation is started...");
        Xls2CsvHelper xls2csv = Xls2CsvHelper.getXls2CsvHelper();

        String inFile = "C:\\Users\\Sanders\\AppData\\Local\\Temp\\_1\\HCPC17_CONTR_ANWEB.xlsx";
        String outFile = "C:\\Users\\Sanders\\AppData\\Local\\Temp\\_1\\out\\HCPC17_CONTR_ANWEB.csv";
        xls2csv.convertHcpcs(inFile, outFile);

        inFile = "C:\\Users\\Sanders\\AppData\\Local\\Temp\\_2\\LOINC_259_PanelsAndForms.xlsx";
        String destFolder = "C:\\Users\\Sanders\\AppData\\Local\\Temp\\_2\\out";
        Map<String, String> sheetNameFilePathMap = new HashMap<String, String>();
        sheetNameFilePathMap.put("ANSWERS", "loinc_answers.txt");
        sheetNameFilePathMap.put("FORMS", "loinc_forms.txt");

        Map<String, String> sheetNameSkiptColumnsAfterNameMap = new HashMap<String, String>();
        sheetNameSkiptColumnsAfterNameMap.put("ANSWERS", "DisplayText");

        xls2csv.convertLoinc(inFile, destFolder, sheetNameFilePathMap, sheetNameSkiptColumnsAfterNameMap);

        System.out.println("*** done");
    }
}