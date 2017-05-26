package com.odysseusinc.convert;

import org.apache.poi.ss.usermodel.*;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

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

    public void convert(String srcFile, String destFile) throws IOException {
        String inputFile = srcFile;
        String outputFile = destFile;

        /**
         * For storing data into CSV files
         */
        StringBuffer data = new StringBuffer();
        FileOutputStream fos = null;
        try {
            fos = new FileOutputStream(outputFile);

            /**
             * Get the workbook object for XLS file
             */
            Workbook workbook = WorkbookFactory.create(new FileInputStream(inputFile));
            /**
             * Get first sheet from the workbook
             */
            Sheet sheet = workbook.getSheetAt(0);
//            Cell cell;
//            Row row;
            for (int i = 0; i < sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);

                if (row != null) {
                    for (int j = 0; j < row.getLastCellNum(); j++) {
                        Cell cell = row.getCell(j);
                        if (cell == null) {
                            data.append(";");
                        } else {
                            cell.setCellType(Cell.CELL_TYPE_STRING);
                            data.append("\"" + cell.toString().trim().replaceAll("\"", "'") + "\"" + ";");
//                            switch (cell.getCellType()) {
//                                case Cell.CELL_TYPE_BOOLEAN:
//                                    data.append("\"" + cell.getBooleanCellValue() + "\"" + ";");
//                                    break;
//
//                                case Cell.CELL_TYPE_NUMERIC:
//                                    data.append("\"" + cell.getNumericCellValue() + "\"" + ";");
//                                    break;
//
//                                case Cell.CELL_TYPE_STRING:
//                                    if (!cell.getStringCellValue().contains("\"")) {
//                                        System.out.println(cell.toString());
//                                        data.append("\"" + cell.getStringCellValue().trim().replaceAll("\"", "'") + "\"" + ";");
//                                    } else {
//                                        data.append(";");
//                                    }
//                                    break;
//
//                                case Cell.CELL_TYPE_BLANK:
//                                    data.append("" + ";");
//                                    break
//
//                                default:
//                                    data.append(cell + ";");
//                            }
                        }
                    }
                    data.append('\n');
                } else {
                    /**
                     * Nothing ?
                     */
                }
            }
//            /**
//             * Iterate through each rows from first sheet
//             */
//            Iterator<Row> rowIterator = sheet.iterator();
//            while (rowIterator.hasNext()) {
//                row = rowIterator.next();
//                // For each row, iterate through each columns
//                Iterator<Cell> cellIterator = row.cellIterator();
//                while (cellIterator.hasNext()) {
//                    cell = cellIterator.next();
//
//                    switch (cell.getCellType()) {
//                        case Cell.CELL_TYPE_BOOLEAN:
//                            data.append("\"" + cell.getBooleanCellValue() + "\"" + ";");
//                            break;
//
//                        case Cell.CELL_TYPE_NUMERIC:
//                            data.append("\"" + cell.getNumericCellValue() + "\"" + ";");
//                            break;
//
//                        case Cell.CELL_TYPE_STRING:
//                            data.append("\"" + cell.getStringCellValue().trim() + "\"" + ";");
//                            break;
//
//                        case Cell.CELL_TYPE_BLANK:
//                            data.append("" + ";");
//                            break;
//
//                        default:
//                            data.append(cell + ";");
//                    }
//                }
//            }
            System.out.println("file converted...");
            fos.write(data.toString().getBytes());
            fos.flush();

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
        System.out.println("Conversion is started...");
        Xls2CsvHelper xls2csv = Xls2CsvHelper.getXls2CsvHelper();

        String inFile = "C:\\Users\\Sanders\\AppData\\Local\\Temp\\1\\HCPCS2017_Trans Report_Alpha.xlsx";
        String outFile = "C:\\Users\\Sanders\\AppData\\Local\\Temp\\1\\HCPCS2017_Trans Report_Alpha.csv";
        xls2csv.convert(inFile, outFile);
        System.out.println("Conversion done");
    }
}