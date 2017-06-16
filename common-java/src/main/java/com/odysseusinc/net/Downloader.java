package com.odysseusinc.net;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.http.Header;
import org.apache.http.HttpResponse;
import org.apache.http.NameValuePair;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.ResponseHandler;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.impl.client.LaxRedirectStrategy;
import org.apache.http.message.BasicNameValuePair;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.util.*;

public class Downloader {

    private final Properties resourceProperties;
    CloseableHttpClient httpClient;

    public Downloader() {
        httpClient = HttpClients.custom()
                .setRedirectStrategy(new LaxRedirectStrategy()) // adds HTTP REDIRECT support to GET and POST methods
                .build();
        // Load resource properties
        this.resourceProperties = new Properties();
        try {
            resourceProperties.load(new FileInputStream("D:\\Projects\\VocabularyUpdate_Odysseus\\Update_UMLS.properties"));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public File download(URL url, File dstFile) {
        try {
            HttpGet get = new HttpGet(url.toURI()); // we're using GET but it could be via POST as well
            File downloaded = httpClient.execute(get, new FileDownloadResponseHandler(dstFile));
            return downloaded;
        } catch (Exception e) {
            throw new IllegalStateException(e);
        } finally {
            IOUtils.closeQuietly(httpClient);
        }
    }

    private List<NameValuePair> toMapNameValuePairs(Map<String, String> params) {
        List<NameValuePair> nvpList = new ArrayList<>();
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

    private void login(String url, String userName, String password) throws IOException {
        CloseableHttpResponse response = null;
        try {
            Map<String, String> params = new HashMap<String, String>();
            params.put("username", userName);
            params.put("password", password);

            HttpPost request = new HttpPost(url);
            if (params != null && !params.isEmpty()) {
                List<NameValuePair> pairList = toMapNameValuePairs(params);
                request.setEntity(new UrlEncodedFormEntity(pairList));
            }

            request.addHeader("Content-Type", "application/x-www-form-urlencoded");

            System.out.println("!!!!! Request headers:");
            List<Header> lHeader = Arrays.asList(request.getAllHeaders());
            for (Header h: lHeader) {
                System.out.println(String.format("\t%s: %s", h.getName(), h.getValue()));
            }

            response = httpClient.execute(request);
        } finally {

        }
    }

    static class FileDownloadResponseHandler implements ResponseHandler<File> {

        private final File target;

        public FileDownloadResponseHandler(File target) {
            this.target = target;
        }

        @Override
        public File handleResponse(HttpResponse response) throws ClientProtocolException, IOException {
            InputStream source = response.getEntity().getContent();
            FileUtils.copyInputStreamToFile(source, this.target);
            return this.target;
        }

    }

    public static void main(String[] args) throws IOException {

        URL rightUrl = new URL("https://utslogin.nlm.nih.gov/cas/login?service=https://download.nlm.nih.gov/umls/kss/2017AA/umls-2017AA-full.zip");
        URL redirectableUrl = new URL("https://utslogin.nlm.nih.gov/cas/login?service=https://download.nlm.nih.gov/umls/kss/2017AA/umls-2017AA-full.zip"); // redirected to cursos.triadworks.com.br

        Downloader downloader = new Downloader();

        String loginUrl = downloader.resourceProperties.getProperty("downloadUpdatePack.umlsFull.fileUrl");
        String userName = downloader.resourceProperties.getProperty("downloadUpdatePack.umls.username");
        String password = downloader.resourceProperties.getProperty("downloadUpdatePack.umls.password");

        downloader.login(loginUrl, userName, password);

        System.out.println("Downloading file through right Url...");
        downloader.download(rightUrl, new File("main-ok.css"));

//        System.out.println("Downloading file through a redirectable Url...");
//        downloader.download(redirectableUrl, new File("main-redirected.css"));
//
    }

}