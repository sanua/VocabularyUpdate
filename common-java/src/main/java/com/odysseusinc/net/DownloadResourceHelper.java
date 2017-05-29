package com.odysseusinc.net;

import com.google.common.base.Joiner;
import com.google.common.io.Files;
import org.apache.commons.io.IOUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.http.*;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.utils.URIBuilder;
import org.apache.http.cookie.Cookie;
import org.apache.http.entity.BufferedHttpEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.impl.cookie.BasicClientCookie;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.protocol.HttpContext;
import org.apache.http.util.EntityUtils;

import java.io.*;
import java.net.URISyntaxException;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Created by Sanders on 5/23/2017.
 */

public class DownloadResourceHelper {
    /**
     * Names of using cookies.
     *
     * COOKIE_JSESSIONID - session identifier on UMLS login service;
     * COOKIE_CASTGC - client authentication cookie for UMLS login service;
     * COOKIE_MOD_AUTH_CAS - client ticket-authentication cookie for UMLS download service.
     */
    public static final String COOKIE_JSESSIONID = "JSESSIONID";
    public static final String COOKIE_CASTGC = "CASTGC";
    public static final String COOKIE_MOD_AUTH_CAS = "MOD_AUTH_CAS";

    private CloseableHttpClient httpClient;
    private File tempDir;
    private Properties resourceProperties;
    /**
     * Presumably "Login Ticket" parameter.
     * Used on user form during authentication, generated by UMLS login service when new session is created.
     */
    private String ltParam;

    /**
     * Class-level cookie store
     */
    private List<Cookie> localCookieStore;

    /**
     * Apache CookieStore for all cookies.
     * Isn't used because of using class-level cookie store.
     */
//    private CookieStore cookieStore;

    /**
     * Instance of Download Helper.
     */
    private static DownloadResourceHelper singleIntance;

    /**
     * Contructor
     */
    private DownloadResourceHelper() {
        this.localCookieStore = new ArrayList<Cookie>();
//        this.cookieStore = new BasicCookieStore();

        // Create HttpClient
        this.httpClient = HttpClients.custom()
                .disableCookieManagement() // disabled auto-cookie management
                .disableRedirectHandling()
                .addInterceptorLast(new HttpRequestInterceptor() {
                    public void process(HttpRequest httpRequest, HttpContext httpContext) throws HttpException, IOException {
//                        String requestMethod = httpRequest.getRequestLine().getMethod();
//                        if (requestMethod.equalsIgnoreCase(HttpGet.METHOD_NAME)) {
//                            /**
//                             * Add GET-specific headers
//                             */
//                            httpRequest.addHeader("Host", "download.nlm.nih.gov");
//                            httpRequest.addHeader("Origin", "https://download.nlm.nih.gov");
//                            httpRequest.addHeader("Referer", "https://download.nlm.nih.gov");
//                        } else if (requestMethod.equalsIgnoreCase(HttpPost.METHOD_NAME)) {
//                            /**
//                             * Add POST-specific headers
//                             */
//                            httpRequest.addHeader("Host", "utslogin.nlm.nih.gov");
//                            httpRequest.addHeader("Origin", "https://utslogin.nlm.nih.gov");
//                            httpRequest.addHeader("Referer", "https://utslogin.nlm.nih.gov");
//                        }
                        /**
                         * Add common request headers
                         */
                        httpRequest.addHeader("Connection", "keep-alive");
                        httpRequest.addHeader("Upgrade-Insecure-Requests", "1");
                        httpRequest.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36");
                        httpRequest.addHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
                        httpRequest.addHeader("Accept-Encoding", "gzip, deflate, sdch, br");
                        httpRequest.addHeader("Accept-Language", "en-US,en;q=0.8,ru;q=0.6,uk;q=0.4");
                        httpRequest.addHeader("Cache-Control", "no-cache");
                        httpRequest.addHeader("Pragma", "no-cache");
                    }
                })
                .addInterceptorLast(new HttpResponseInterceptor() {
                    public void process(HttpResponse httpResponse, HttpContext httpContext) throws HttpException, IOException {
                        /**
                         * Adding of cookie from response to class-level local storage.
                         */
                        saveClientCookie(httpResponse);
                    }
                })
                .build();

        // Prepare temporary storage for content
        this.tempDir = Files.createTempDir();
        this.tempDir.deleteOnExit();

        // Load resource properties
        this.resourceProperties = new Properties();
        try {
            resourceProperties.load(new FileInputStream("./Update_LOINC.properties"));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * Extract header value from response
     *
     * @param response
     * @param name
     * @return
     */
    private String getResponseHeaderValue(HttpResponse response, String name) {
        Header header = response.getLastHeader(name);
        if (header == null) {
            return "";
        } else {
            return header.getValue();
        }
    }

    /**
     * Convert array to List
     *
     * @param objects
     * @return
     */
    private <T> List<T> getListFromArray(T[] objects) {
        List<T> result = new ArrayList<T>();
        for (T c: objects) {
            if (c != null) {
                result.add(c);
            }
        }
        return result;
    }

    /**
     * Return all saved client's cookies.
     *
     * @return
     */
    private List<Cookie> getAllStoredCookies() {
        List<Cookie> ckList = new ArrayList<Cookie>();
        Iterator<Cookie> it = this.localCookieStore.iterator();
        while (it.hasNext()) {
            ckList.add(it.next());
        }
        return ckList;
    }

    /**
     * Get client cookie from local storage.
     *
     * @param name
     * @return
     */
    private Cookie getClientCookie(String name) {
        Cookie cookie = null;
        Iterator<Cookie> it = this.localCookieStore.iterator();
        while (it.hasNext()) {
            Cookie c = it.next();
            if (c.getName().equalsIgnoreCase(name)) {
                cookie = c;
                break;
            }
        }
        return cookie;
    }

    /**
     * Class-level Cookie Storage.
     *
     * @param request
     */
    private void saveClientCookie(HttpResponse request) {
        Header cookieHeader = request.getLastHeader("Set-Cookie");
        if (cookieHeader == null)
            return;
        String nameValue = cookieHeader.getValue().substring(0, cookieHeader.getValue().indexOf(";"));
        Cookie newCookie = new BasicClientCookie(nameValue.split("=")[0], nameValue.split("=")[1]);

        Iterator<Cookie> it = this.localCookieStore.iterator();
        while (it.hasNext()) {
            Cookie c = it.next();
            if (c.getName().equalsIgnoreCase(newCookie.getName()))
                return;
        }
        this.localCookieStore.add(newCookie);
    }

    /**
     * Add multiple cookies to response.
     *
     * @param request
     * @param cookies
     * @return
     */
    private HttpRequest setRequestCookies(HttpRequest request, List<Cookie> cookies) {
        if (cookies == null || cookies.isEmpty())
            return request;

        StringBuilder sb = new StringBuilder();
        for (Cookie c: cookies) {
            if (sb.toString().length() != 0)
                sb.append(";");
            sb.append(String.format("%s=%s", c.getName(), c.getValue()));
        }
        request.addHeader("Cookie", sb.toString());
        return request;
    }

    /**
     * Convert parameter's map to name-value format, for convenient usage for Apache's classes.
     *
     * @param params
     * @return
     */
    private List<NameValuePair> toMapNameValuePairs(Map<String, String> params) {
        List<NameValuePair> nvpList = new ArrayList<NameValuePair>();
        Iterator<Map.Entry<String, String>> it = params.entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry<String, String> entry = it.next();
            String name = entry.getKey();
            String value = entry.getValue();
            if (StringUtils.isNotBlank(name) && StringUtils.isNoneBlank(value))
                nvpList.add(new BasicNameValuePair(name, value));
        }
        return nvpList;
    }

    /**
     * Prepare GET request.
     *
     * @param url
     * @return
     * @throws IOException
     * @throws URISyntaxException
     */
    private HttpGet prepareGet(String url) throws IOException, URISyntaxException {
        return prepareGet(url, null, null);
    }

    /**
     * Prepare GET request with adding multiple cookies.
     *
     * @param url
     * @param cookies
     * @return
     * @throws IOException
     * @throws URISyntaxException
     */
    private HttpGet prepareGet(String url, List<Cookie> cookies) throws IOException, URISyntaxException {
        return prepareGet(url, null, cookies);
    }

    /**
     * Prepare parametrised GET request with adding multiple cookies.
     *
     * @param url
     * @param params
     * @param cookies
     * @return
     * @throws IOException
     * @throws URISyntaxException
     */
    private HttpGet prepareGet(String url, Map<String, String> params, List<Cookie> cookies) throws IOException, URISyntaxException {
        if (params != null && !params.isEmpty()) {
            URIBuilder uriBuilder = new URIBuilder(url);
            List<NameValuePair> pairList = toMapNameValuePairs(params);
            uriBuilder.addParameters(pairList);
            url = uriBuilder.toString();
        }
        HttpGet request = new HttpGet(url);
        setRequestCookies(request, cookies);
        return request;
    }

    /**
     * Prepare parametrised POST request
     *
     * @param url
     * @param params
     * @return
     * @throws IOException
     * @throws URISyntaxException
     */
    private HttpPost preparePost(String url, Map<String, String> params) throws IOException, URISyntaxException {
        return preparePost(url, params, null);
    }

    /**
     * Prepare parametrised POST request with adding multiple cookies.
     *
     * @param url
     * @param params
     * @param cookies
     * @return
     * @throws IOException
     * @throws URISyntaxException
     */
    private HttpPost preparePost(String url, Map<String, String> params, List<Cookie> cookies) throws IOException, URISyntaxException {
        HttpPost request = new HttpPost(url);
        if (params != null && !params.isEmpty()) {
            List<NameValuePair> pairList = toMapNameValuePairs(params);
            request.setEntity(new UrlEncodedFormEntity(pairList));
        }
        setRequestCookies(request, cookies);
        return request;
    }

    /**
     * Return resource property value by it's name
     *
     * @param name
     * @return
     */
    public static String getPropertyByName(String name) {
        return getDownloadResourceHelper().resourceProperties.getProperty(name);
    }

    /**
     * Get instance
     *
     * @return
     */
    public static DownloadResourceHelper getDownloadResourceHelper() {
        if (singleIntance == null) {
            singleIntance = new DownloadResourceHelper();
        }
        return singleIntance;
    }

    // Login and download resource
    public boolean downloadResourceUmls() throws IOException {
        CloseableHttpResponse response = null;
        String url = getPropertyByName("downloadUpdatePack.umls.loginUrl");

        // REQUEST 1
        // Just to get first JSESSION cookie
        try {
            HttpGet request = prepareGet(url);

            System.out.println(String.format("\n\n\n!!! REQUEST 1 %s url: %s", request.getMethod(), url));
            System.out.println("\n!!! REQUEST 1 request headers:\n" + Joiner.on("\n").join(request.getAllHeaders()));
            response = httpClient.execute(request);

            System.out.println("\n!!! REQUEST 1 status line: " + response.getStatusLine());
            System.out.println("\n!!! REQUEST 1 response content type: " + getResponseHeaderValue(response, "Content-Type"));
            System.out.println("\n!!! REQUEST 1 response headers:\n" + Joiner.on("\n").join(response.getAllHeaders()));
            String responseBody = EntityUtils.toString(response.getEntity()).trim();
            System.out.println("\n!!! REQUEST 1 response:\n" + ((responseBody.length() == 0) ? "EMPTY" : (getResponseHeaderValue(response, "Content-Type").indexOf("text") < 0) ? "BINARY" : responseBody));

            // Remember dynamically generated presumably "Login Ticket" form parameter
            Pattern ltPattern = Pattern.compile("name=\"lt\" value=\"(\\w+)\"");
            Matcher m = ltPattern.matcher(responseBody);
            while (m.find()) {
                this.ltParam = m.group(1);
            }
        } catch (Exception e) {
            System.out.println("Error occurs: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (response != null) {
                response.close();
            }
        }

        // REQUEST 2
        // Login
        try {
            String userName = getPropertyByName("downloadUpdatePack.umls.username");
            String password = getPropertyByName("downloadUpdatePack.umls.password");
            Map<String, String> params = new HashMap<String, String>();
            params.put("username", userName);
            params.put("password", password);
            params.put("lt", this.ltParam);
            params.put("_eventId", "submit");
            params.put("submit", "Sign In");
            List<Cookie> cookies = getListFromArray(new Cookie[] {
                    getClientCookie(COOKIE_JSESSIONID)
            });
            HttpPost request = preparePost(url, params, cookies);
            request.addHeader("Content-Type", "application/x-www-form-urlencoded");

            System.out.println(String.format("\n\n\n!!! REQUEST 2 %s url: %s", request.getMethod(), url));
            System.out.println("\n!!! REQUEST 2 request headers:\n" + Joiner.on("\n").join(request.getAllHeaders()));
            response = httpClient.execute(request);

            System.out.println("\n!!! REQUEST 2 response status line: " + response.getStatusLine());
            System.out.println("\n!!! REQUEST 2 response content type: " + getResponseHeaderValue(response, "Content-Type"));
            System.out.println("\n!!! REQUEST 2 response headers:\n" + Joiner.on("\n").join(response.getAllHeaders()));
            String responseBody = EntityUtils.toString(response.getEntity()).trim();
            System.out.println("\n!!! REQUEST 2 response:\n" + ((responseBody.length() == 0) ? "EMPTY" : (getResponseHeaderValue(response, "Content-Type").indexOf("text") < 0) ? "BINARY" : responseBody));
        } catch (Exception e) {
            System.out.println("Exception occurs: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (response != null)
                response.close();
        }

        // REQUEST 3
        // Get ticket for requested resource
        url = getPropertyByName("downloadUpdatePack.cptMappings.fileUrl");
        try {
            List<Cookie> cookies = getListFromArray(new Cookie[] {
                    getClientCookie(COOKIE_JSESSIONID),
                    getClientCookie(COOKIE_CASTGC)
            });
            HttpGet request = prepareGet(url, cookies);

            System.out.println(String.format("\n\n\n!!! REQUEST 3 %s url: %s", request.getMethod(), url));
            System.out.println("\n!!! REQUEST 3 request headers:\n" + Joiner.on("\n").join(request.getAllHeaders()));
            response = httpClient.execute(request);

            System.out.println("\n!!! REQUEST 3 response status line: " + response.getStatusLine());
            System.out.println("\n!!! REQUEST 3 response content type: " + getResponseHeaderValue(response, "Content-Type"));
            System.out.println("\n!!! REQUEST 3 response headers:\n" + Joiner.on("\n").join(response.getAllHeaders()));
            String responseBody = EntityUtils.toString(response.getEntity()).trim();
            System.out.println("\n!!! REQUEST 3 response:\n" + ((responseBody.length() == 0) ? "EMPTY" : (getResponseHeaderValue(response, "Content-Type").indexOf("text") < 0) ? "BINARY" : responseBody));

            /**
             * Get URL for further processing
             */
            url = getResponseHeaderValue(response, "Location");
        } catch (Exception e) {
            System.out.println("Error occurs: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (response != null)
                response.close();
        }

        // REQUEST 4
        // Authorize on download service
        try {
            HttpGet request = prepareGet(url);

            System.out.println(String.format("\n\n\n!!! REQUEST 4 %s url: %s", request.getMethod(), url));
            System.out.println("\n!!! REQUEST 4 request headers:\n" + Joiner.on("\n").join(request.getAllHeaders()));
            response = httpClient.execute(request);

            System.out.println("\n!!! REQUEST 4 response status line: " + response.getStatusLine());
            System.out.println("\n!!! REQUEST 4 response content type: " + getResponseHeaderValue(response, "Content-Type"));
            System.out.println("\n!!! REQUEST 4 response headers:\n" + Joiner.on("\n").join(response.getAllHeaders()));
            String responseBody = EntityUtils.toString(response.getEntity()).trim();
            System.out.println("\n!!! REQUEST 4 response:\n" + ((responseBody.length() == 0) ? "EMPTY" : (getResponseHeaderValue(response, "Content-Type").indexOf("text") < 0) ? "BINARY" : responseBody));

            /**
             * Get URL for further processing
             */
            url = getResponseHeaderValue(response,"Location");
        } catch (Exception e) {
            System.out.println("Error occurs: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (response != null)
                response.close();
        }

        // REQUEST 5
        // Download resource
        String fileName = getPropertyByName("downloadUpdatePack.cptMappings.fileName");
        OutputStream outputStream = null;
        try {
            List<Cookie> cookies = getListFromArray(new Cookie[] {
                    getClientCookie(COOKIE_MOD_AUTH_CAS)
            });
            HttpGet request = prepareGet(url, cookies);

            System.out.println(String.format("\n\n\n!!! REQUEST 5 %s url: %s", request.getMethod(), url));
            System.out.println("\n!!! REQUEST 5 request headers:\n" + Joiner.on("\n").join(request.getAllHeaders()));
            response = httpClient.execute(request);

            System.out.println("\n!!! REQUEST 5 response status line: " + response.getStatusLine());
            System.out.println("\n!!! REQUEST 5 response content type: " + getResponseHeaderValue(response, "Content-Type"));
            System.out.println("\n!!! REQUEST 5 response headers:\n" + Joiner.on("\n").join(response.getAllHeaders()));

            // Buffer response content
            BufferedHttpEntity bufEntity = new BufferedHttpEntity(response.getEntity());
            StringWriter writer = new StringWriter();
            IOUtils.copy(bufEntity.getContent(), writer, Consts.UTF_8);
            String responseBody = writer.toString().trim();
            System.out.println("\n!!! REQUEST 5 response:\n" + ((responseBody.length() == 0) ? "EMPTY" : (getResponseHeaderValue(response, "Content-Type").indexOf("text") < 0) ? "BINARY" : responseBody));

            // Eval downloaded file name
            String contentDisposition = getResponseHeaderValue(response, "Content-Disposition");
            System.out.println("content-disposition header: " + contentDisposition);
            if (contentDisposition.length() > 0) {
                fileName = contentDisposition.substring(contentDisposition.lastIndexOf("filename") + 9).replace("\"", "").replace(";", "");
            }
            String filePath = String.format("%s%s%s", tempDir.getPath(), File.separator, fileName);

            String contentLength = getResponseHeaderValue(response,"Content-Length");
            System.out.println(String.format("Downloaded '%s' file with %s bytes", fileName, contentLength));

            // Save file to stream
            outputStream = new FileOutputStream(new File(filePath));
            IOUtils.copy(bufEntity.getContent(), outputStream);
            outputStream.flush();
            System.out.println("File saved to: " + filePath);
        } catch (Exception e) {
            System.out.println("Error occurs: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (response != null) {
               response.close();
            }
            if (outputStream != null) {
                outputStream.close();
            }
        }
        return true;
    }

    public boolean loginLoinc() throws IOException {
        CloseableHttpResponse response = null;

        // Login LOINC services
        String url = getPropertyByName("downloadUpdatePack.loinc.loginUrl");
        try {
            String userName = getPropertyByName("downloadUpdatePack.loinc.username");
            String password = getPropertyByName("downloadUpdatePack.loinc.password");
            Map<String, String> params = new HashMap<String, String>();
            params.put("log", userName);
            params.put("pwd", password);
            params.put("wp-submit", "Log In");
            HttpPost request = preparePost(url, params);

            System.out.println(String.format("\n\n\n!!! LOGIN REQUEST %s url: %s", request.getMethod(), url));
            System.out.println("\n!!! LOGIN REQUEST request headers:\n" + Joiner.on("\n").join(request.getAllHeaders()));
            response = httpClient.execute(request);

            System.out.println("\n!!! LOGIN REQUEST response status line: " + response.getStatusLine());
            System.out.println("\n!!! LOGIN REQUEST response content type: " + getResponseHeaderValue(response, "Content-Type"));
            System.out.println("\n!!! LOGIN REQUEST response headers:\n" + Joiner.on("\n").join(response.getAllHeaders()));
            String responseBody = EntityUtils.toString(response.getEntity()).trim();
            System.out.println("\n!!! LOGIN REQUEST response:\n" + ((responseBody.length() == 0) ? "EMPTY" : (getResponseHeaderValue(response, "Content-Type").indexOf("text") < 0) ? "BINARY" : responseBody));
            return true;
        } catch (Exception e) {
            System.out.println("Error occurs: " + e.getMessage());
            e.printStackTrace();
            return false;
        } finally {
            if (response != null) {
                response.close();
            }
        }
    }

    public void downloadResourceLoinc(String fileUrl, String defaultFileName, String packageDescription) throws IOException {
        String url = fileUrl;
        String fileName = defaultFileName;
        OutputStream outputStream = null;
        CloseableHttpResponse response = null;

        try {
            Map<String, String> params = new HashMap<String, String>();
            params.put("tc_accepted", "1");
            params.put("tc_submit", "Download");
            List<Cookie> cookies = getAllStoredCookies();
            HttpPost request = preparePost(url, params, cookies);
            System.out.println(String.format("\n\n\n!!! DOWNLOAD REQUEST %s url: %s", request.getMethod(), url));
            System.out.println("\n!!! DOWNLOAD REQUEST request headers:\n" + Joiner.on("\n").join(request.getAllHeaders()));
            response = httpClient.execute(request);

            int responseCode = response.getStatusLine().getStatusCode();
            if (responseCode != HttpStatus.SC_OK) {
                throw new HttpException(String.format("Unable to download %s", packageDescription));
            } else if (getResponseHeaderValue(response, "Content-Type").indexOf("zip") < 0) {
                throw new HttpException(String.format("%s is not a ZIP archive", packageDescription));
            }

            System.out.println("\n!!! DOWNLOAD REQUEST response status line: " + response.getStatusLine());
            System.out.println("\n!!! DOWNLOAD REQUEST response content type: " + getResponseHeaderValue(response, "Content-Type"));
            System.out.println("\n!!! DOWNLOAD REQUEST response headers:\n" + Joiner.on("\n").join(response.getAllHeaders()));

            // Buffer response content
            BufferedHttpEntity bufEntity = new BufferedHttpEntity(response.getEntity());
            StringWriter writer = new StringWriter();
            IOUtils.copy(bufEntity.getContent(), writer, Consts.UTF_8);
            String responseBody = writer.toString().trim();
            System.out.println("\n!!! DOWNLOAD REQUEST response:\n" + ((responseBody.length() == 0) ? "EMPTY" : (getResponseHeaderValue(response, "Content-Type").indexOf("text") < 0) ? "BINARY" : responseBody));

            // Eval downloaded file name
            String contentDisposition = getResponseHeaderValue(response, "Content-Disposition");
            System.out.println("content-disposition header: " + contentDisposition);
            if (contentDisposition.length() > 0)
                fileName = contentDisposition.substring(contentDisposition.lastIndexOf("filename") + 9).replace("\"", "").replace(";", "");
            String filePath = String.format("%s%s%s", tempDir.getPath(), File.separator, fileName);

            String contentLength = getResponseHeaderValue(response,"Content-Length");
            System.out.println(String.format("Downloaded '%s' file with %s bytes", fileName, contentLength));

            // Save file to stream
            outputStream = new FileOutputStream(new File(filePath));
            IOUtils.copy(bufEntity.getContent(), outputStream);
            outputStream.flush();
            System.out.println("File saved to: " + filePath);

        } catch (Exception e) {
            System.out.println("Error occurs: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (response != null) {
                response.close();
            }
            if (outputStream != null) {
                outputStream.close();
            }
        }
    }

    public static void main(String[] args) throws IOException {
        DownloadResourceHelper downloadHelper = DownloadResourceHelper.getDownloadResourceHelper();

        // Login LOINC service
        System.out.println("\nLogin LOINC service...");
        downloadHelper.loginLoinc();

        // Download 'Full Set' package
        String packageDescription = getPropertyByName("downloadUpdatePack.fullSet.description");
        System.out.println(String.format("\nDownload %s...", packageDescription));
        String fileUrl = getPropertyByName("downloadUpdatePack.fullSet.fileUrl");
        String defaultFileName = getPropertyByName("downloadUpdatePack.fullSet.fileName");
        downloadHelper.downloadResourceLoinc(fileUrl, defaultFileName, packageDescription);

         // Download 'Multiaxial Hierarchy' package
        packageDescription = getPropertyByName("downloadUpdatePack.multiaxialHierarchy.description");
        System.out.println(String.format("\nDownload %s...", packageDescription));
        fileUrl = getPropertyByName("downloadUpdatePack.multiaxialHierarchy.fileUrl");
        defaultFileName = getPropertyByName("downloadUpdatePack.multiaxialHierarchy.fileName");
        downloadHelper.downloadResourceLoinc(fileUrl, defaultFileName, packageDescription);

         // Download 'Panels and Forms' package
        packageDescription = getPropertyByName("downloadUpdatePack.panelsForms.description");
        System.out.println(String.format("\nDownload %s...", packageDescription));
        fileUrl = getPropertyByName("downloadUpdatePack.panelsForms.fileUrl");
        defaultFileName = getPropertyByName("downloadUpdatePack.panelsForms.fileName");
        downloadHelper.downloadResourceLoinc(fileUrl, defaultFileName, packageDescription);

         // Download 'CT Expression Association' package
        packageDescription = getPropertyByName("downloadUpdatePack.expressionAssociation.description");
        System.out.println(String.format("\nDownload %s...", packageDescription));
        fileUrl = getPropertyByName("downloadUpdatePack.expressionAssociation.fileUrl");
        defaultFileName = getPropertyByName("downloadUpdatePack.expressionAssociation.fileName");
        downloadHelper.downloadResourceLoinc(fileUrl, defaultFileName, packageDescription);

        // Login and download from UMLS service
        System.out.println("\nLogin and download from UMLS service...");
        downloadHelper.downloadResourceUmls();
    }
}