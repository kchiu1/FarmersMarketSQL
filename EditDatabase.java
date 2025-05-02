import java.sql.*;
import java.util.*;
import java.io.*;

/**
 * Combined Farmers Market Database Editor with Market and Review classes.
 * @author chiuk2
 */
public class EditDatabase {
    
    /**
     * Constructor for EditDatabase, does nothing!
     */
    public EditDatabase() {}
    
    /**
     * Main method
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        Connection con = null;
        Scanner in = null;
        in = new Scanner(System.in);
        String username, port, password;
        System.out.println("What is your username?");
        username = in.nextLine();

        System.out.println("What is your port number?");
        port = in.nextLine();

        System.out.println("What is your password?");
        password = in.nextLine();
        in.close();
        String url = "jdbc:mysql://localhost:" + port + "/farmersmarkets?useSSL=false&serverTimezone=America/Los_Angeles";

        
        try {
            con = DriverManager.getConnection(url, username, password);
            
            try {
                FileInputStream fis = new FileInputStream("Export.csv");
                System.out.println("Connection successful! Uploading to database. Please wait for this to finish.");
                in = new Scanner(fis);
                String[] colName = new String[] {};
                String[] colData = new String[] {};
                
                if (in.hasNextLine()) {
                    String line = in.nextLine();
                    colName = line.split(",");
                    for (int i=0; i < colName.length; i++) {
                        System.out.println(i + " " + colName[i]);
                    }
                }

                String query = "INSERT INTO FMCategory (id, name) VALUES (?, ?)";
                PreparedStatement stat = con.prepareStatement(query);
                for (int i=28; i <= 57; i++) {
                    stat.setInt(1, i-27);
                    stat.setString(2, colName[i]);
                    stat.executeUpdate();
                    stat.clearParameters();
                }

                while(in.hasNextLine()) {
                    String line = in.nextLine();
                    colData = line.split(",");
                    try {
                        int[] FMInfo = new int[] {0,1,7,8,9,10,11,20,21};
                        query = "INSERT INTO FMInfo (fmid, name, street, city, county, state, zip, x, y) " +
                                                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) ";
                        stat = con.prepareStatement(query);
                        for (int i=0; i < FMInfo.length; i++) {
                            stat.setString(i+1, colData[FMInfo[i]]);
                            System.out.println(i + " " + colData[FMInfo[i]]);
                        }
                        stat.executeUpdate();
                        stat.clearParameters();

                        int[] FMOpen = new int[] {0,12,14,16,18,13,15,17,19};	
                        query = "INSERT INTO FMOpen (fmid, season, dates, hours) VALUES (?, ?, ?, ?)";
                        stat = con.prepareStatement(query);
                        for (int i=0; i < 4; i++) {
                            if (colData[12+(i*2)].isEmpty() && colData[13+(i*2)].isEmpty()) {
                                continue;
                            }
                            stat.setString(1, colData[0]);
                            stat.setInt(2, i+1);
                            stat.setString(3, colData[12+(i*2)]);
                            stat.setString(4, colData[13+(i*2)]);

                            stat.executeUpdate();
                            stat.clearParameters();
                        }

                        int[] FMMedia = new int[] {0,2,3,4,5,6};
                        query = "INSERT INTO FMMedia (fmid, media, url) VALUES (?, ?, ?)";
                        stat = con.prepareStatement(query);
                        for (int i=1; i < FMMedia.length; i++) {
                            if (colData[FMMedia[i]].isEmpty()) {
                                continue;
                            }
                            stat.setString(1, colData[0]);
                            stat.setString(2, colName[FMMedia[i]]);
                            stat.setString(3, colData[FMMedia[i]]);

                            stat.executeUpdate();
                            stat.clearParameters();
                        }

                        int[] FMPayment = new int[] {0,23,24,25,26,27};
                        query = "INSERT INTO FMPayment (fmid, type) VALUES (?, ?)";
                        stat = con.prepareStatement(query);
                        for (int i=1; i < FMPayment.length; i++) {
                            if (!colData[FMPayment[i]].equals("Y")) {
                                    continue;
                            }
                            stat.setString(1, colData[0]);
                            stat.setString(2, colName[FMPayment[i]]);

                            stat.executeUpdate();
                            stat.clearParameters();
                        }

                        query = "INSERT INTO FMProduct (fmid, categoryid) VALUES (?, ?)";
                        stat = con.prepareStatement(query);
                        for (int i=28; i <= 57; i++) {
                            if (!colData[i].equals("Y")) {
                                continue;
                            }
                            stat.setString(1, colData[0]);
                            stat.setInt(2, i-27);

                            stat.executeUpdate();
                            stat.clearParameters();
                        }       
                    }
                    catch (Exception ex) {
                        System.out.println(ex.getMessage());
                    }
		        }              
            } catch (IOException e) {
                e.printStackTrace();
            }
        } catch (SQLException ex) {
            for (Throwable t : ex) {
                System.out.println(t.getMessage());
            }
            System.out.println("Opening connection was unsuccessful!");
        } finally {
            if (con != null) {
                try {
                    con.close();
                }
                catch (SQLException ex) {
                    for (Throwable t : ex) {
                        System.out.println(t.getMessage());
                    }
                    System.out.println("Closing connection was unsuccessful!");
                }
            }
            if(in != null) {
                in.close();
            }
        }
    }
    
    /**
     * Read from the database
     * @return list of markets
     */
    public List<Market> readFromDatabase() {
        int[] colData = new int[] {};
        String url = "jdbc:mysql://localhost:3306/farmersmarkets?useSSL=false";
        Connection con = null;
        try {
            con = DriverManager.getConnection(url, "root", "M@y!!S^3L15a4uua");
            Statement stmt = con.createStatement();
            String query = "SELECT * FROM FMInfo";

        } catch (SQLException ex) {
            System.out.println("Opening connection was unsuccessful!");
        } finally {
            if (con != null) {
                try {
                    con.close();
                }
                catch (SQLException ex) {
                    System.out.println("Closing connection was unsuccessful!");
                }
            }
        }
        return null;
    }

    /**
     * Market class representing a farmers market
     */
    public static class Market {
        private final String[] paymentNames = new String[] {
            "Credit", "WIC", "WICcash", "SFMNP", "SNAP"
        };
        
        private final String[] foodNames = new String[] {
            "Baked goods", "Cheese", "Crafts", "Flowers", "Eggs", "Seafood", "Herbs", "Vegetables", 
            "Honey", "Jams", "Maple", "Meat", "Nursery", "Nuts", "Plants", "Poultry", "Prepared", 
            "Soap", "Trees", "Wine", "Coffee", "Beans", "Fruits", "Grains", "Juices", "Mushrooms", 
            "Pet Food", "Tofu", "Wild Harvested", "Organic"
        };

        private List<Review> reviews;
        private int FMID;
        private String MarketName;
        private String[] locationData = new String[7];
        private String[] seasonData = new String[8];
        private List<String> mediaSites = new ArrayList<String>();
        private List<String> payments = new ArrayList<String>();
        private List<String> availableFoods = new ArrayList<String>();
        private boolean gotDetail;

        /**
         * Constructor for Market from CSV data
         * @param dataString the data string
         */
        public Market(String dataString) {
            String[] data = dataString.split(",");
            reviews = new ArrayList<>();
            gotDetail = true;

            FMID = Integer.parseInt(data[0].strip());
            MarketName = data[1].strip();

            locationData[0] = data[7].strip();
            locationData[1] = data[8].strip();
            locationData[2] = data[9].strip();
            locationData[3] = data[10].strip();
            locationData[4] = data[11].strip();
            locationData[5] = data[20].strip();
            locationData[6] = data[21].strip();

            seasonData[0] = data[12].strip();
            seasonData[1] = data[13].strip();
            seasonData[2] = data[14].strip();
            seasonData[3] = data[15].strip();
            seasonData[4] = data[16].strip();
            seasonData[5] = data[17].strip();
            seasonData[6] = data[18].strip();
            seasonData[7] = data[19].strip();

            if (!data[2].strip().isEmpty()) {
                mediaSites.add("Website");
                mediaSites.add(data[2].strip());
            }
            if (!data[3].strip().isEmpty()) {
                mediaSites.add("Facebook");
                mediaSites.add(data[3].strip());
            }
            if (!data[4].strip().isEmpty()) {
                mediaSites.add("Twitter");
                mediaSites.add(data[4].strip());
            }
            if (!data[5].strip().isEmpty()) {
                mediaSites.add("Youtube");
                mediaSites.add(data[5].strip());
            }
            if (!data[6].strip().isEmpty()) {
                mediaSites.add("Other");
                mediaSites.add(data[5].strip());
            }

            for(int i = 0; i < 5; i++) {
                if(data[22 + i].strip().equals("Y")) {
                    payments.add(paymentNames[i]);
                }
            }

            for(int i = 0; i < 30; i++) {
                if(data[27 + i].strip().equals("Y")) {
                    availableFoods.add(foodNames[i]);
                }
            }
        }

        /**
         * Constructor for Market with basic info
         */
        public Market(int fmid, String name, String street, String city, String county, 
              String state, String zip, String x, String y) {
            FMID = fmid;
            MarketName = name;
            locationData[0] = street;
            locationData[1] = city;
            locationData[2] = county;
            locationData[3] = state;
            locationData[4] = zip;
            locationData[5] = x;
            locationData[6] = y;
            gotDetail = false;
            reviews = new ArrayList<>();
        } 

        /**
         * Default constructor
         */
        public Market() {
            gotDetail = false;
            reviews = new ArrayList<>();
        }

        // All getter and setter methods from original Market class
        public boolean hasDetail() { return gotDetail; }
        public void setDetail() { gotDetail = true; }
        public void setSeasonData(int index, String str) { seasonData[index] = str.strip(); }
        public void addMediaSites(String media, String url) { mediaSites.add(media); mediaSites.add(url); }
        public void addPayment(String type) { payments.add(type); }
        public void addAvailableFood(String category) { availableFoods.add(category); }
        public List<Review> getReviews() { return reviews; }
        public int getFMID() { return FMID; }
        public String getMarketName() { return MarketName; }
        public String getStreet() { return locationData[0]; }
        public String getCity() { return locationData[1]; }
        public String getCounty() { return locationData[2]; }
        public String getState() { return locationData[3]; }
        public String getZip() { return locationData[4]; }
        public String getX() { return locationData[5]; }
        public String getY() { return locationData[6]; }
        public String getUrl(String site) {
            for (int i=0; i < mediaSites.size(); i=i+2) {
                if (mediaSites.get(i).equals(site)) {
                    return mediaSites.get(i+1);
                }
            }
            return "";
        }
        public String getWebsite() { return getUrl("Website"); }
        public String getFacebook() { return getUrl("Facebook"); }
        public String getTwitter() { return getUrl("Twitter"); }
        public String getYoutube() { return getUrl("Youtube"); }
        public String getOtherMedia() { return getUrl("OtherMedia"); }
        public String getSeason1Date() { return seasonData[0]; }
        public String getSeason1Time() { return seasonData[1]; }
        public String getSeason2Date() { return seasonData[2]; }
        public String getSeason2Time() { return seasonData[3]; }
        public String getSeason3Date() { return seasonData[4]; }
        public String getSeason3Time() { return seasonData[5]; }
        public String getSeason4Date() { return seasonData[6]; }
        public String getSeason4Time() { return seasonData[7]; }
        public List<String> getMediaSites() { return mediaSites; }
        public List<String> getPayments() { return payments; }
        public List<String> getAvailableFoods() { return availableFoods; }
        public void addReview(Review review) {
            if(review.getReview().length() == 0 || review.getName().length() == 0) {
                return;
            }
            reviews.add(0, review);
        }
    }

    /**
     * Review class representing a market review
     */
    public static class Review {
        private String name;
        private String review;
        private int rating;

        /**
         * Constructor
         * @param name the reviewer name
         * @param review the review text
         * @param rating the rating (0-5)
         */
        public Review(String name, String review, int rating) {
            this.name = name;
            this.review = review;
            this.rating = rating;
        }

        public String getName() { return name; }
        public String getReview() { return review; }
        public int getRating() { return rating; }
        
        public String toString() {
            String reviewString = name;
            if(rating == 0) {
                reviewString += "\n[Informational Review]";
            } else {
                reviewString += "\n[Rating: ";
                for(int i = 0; i < rating; i++) {
                    reviewString += "⭐";
                }
                reviewString += "]";
            }
            for(int i = 0; i < review.length(); i++) {
                if(i % 50 == 0) {
                    reviewString += "\n";
                }
                reviewString += review.charAt(i);
            }
            reviewString += "\n";
            return reviewString;
        }
    }
}