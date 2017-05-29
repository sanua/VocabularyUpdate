package com.odysseusinc.convert;

import org.apache.commons.io.FileUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.poi.ss.usermodel.*;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.File;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

/**
 * Created by Sanders on 5/26/2017.
 */
public class Xls2CsvHelper {

    private static Xls2CsvHelper singleInstance;

    private Xls2CsvHelper() {
    }

    public static Xls2CsvHelper getXls2CsvHelper() {
        if (singleInstance == null) {
            singleInstance = new Xls2CsvHelper();
        }
        return singleInstance;
    }

    private String convertSheetByName(Workbook workbook) {
        return convertSheetByName(workbook, null, null);
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
                            data.append("\"" + cellText.replaceAll("\"", "'").replaceAll("[\\n\\r]", " ") + "\"");
                            if (j < skipColumnNumber && (j < sheet.getLastRowNum() - 1)) {
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


    public void convertHcpcs(String inputFile, String outputFile) throws IOException {
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
            fos.write(data.getBytes());
            fos.flush();
            System.out.println("\tConversion of HCPCS data done");
        } catch (Exception e) {
            System.out.println("Error occurs: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (fos != null) {
                fos.close();
            }
        }
    }

    public void convertLoinc(String inputFile, String destFolder, Map<String, String> sheetNameFilePathMap, Map<String, String> sheetNameSkiptColumnsAfterNameMap) throws IOException {
        System.out.println("\n\tConversion of LOINC data started");
        /**
         * Check if input Except file exists
         */
        if (!(new File(inputFile).exists())) {
            throw new IOException(String.format("No input excel file found by name: %s", inputFile));
        }
        /**
         * Check output folder exists, if not - create it, otherwise - clean it
         */
        File f = new File(destFolder);
        if (!f.exists()) {
            f.mkdir();
        } else {
            FileUtils.cleanDirectory(f);
        }

        String data;
        FileOutputStream fos = null;
        try {
            /**
             * Get the workbook object for XLS file
             */
            Workbook workbook = WorkbookFactory.create(new FileInputStream(inputFile));

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
                StringBuilder savedFileFullPath = new StringBuilder(destFolder);
                if (!destFolder.endsWith(File.separator))
                    savedFileFullPath.append(File.separator);
                savedFileFullPath.append(fileName);
                System.out.println(String.format("\tConversion of Sheet '%s' done. Saved to: '%s'.", sheetName, savedFileFullPath.toString()));
                fos = new FileOutputStream(savedFileFullPath.toString());
                fos.write(data.getBytes());
                fos.flush();
            }
            System.out.println("\tConversion of LOINC data done");
        } catch (Exception e) {
            System.out.println("Error occurs: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (fos != null) {
                fos.close();
            }
        }
    }

    public static void main(String[] args) throws IOException {
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