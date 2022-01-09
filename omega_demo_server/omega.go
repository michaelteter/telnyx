package main

import (
	"fmt"
	"math/rand"
	"net/http"

	"github.com/gin-gonic/gin"
)

type Product struct {
	Id           uint   `json:"id"`
	Name         string `json:"name"`
	Price        string `json:"price"`
	Category     string `json:"category"`
	Discontinued bool   `json:"discontinued"`
}

func randomPrice() string {
	return fmt.Sprintf("$%d.%02d", rand.Intn(100)+2, rand.Intn(100))
}

func chair() Product {
	return Product{
		Id:           123456,
		Name:         "Fancy Chair",
		Price:        randomPrice(),
		Category:     "chair",
		Discontinued: false,
	}
}

func table() Product {
	return Product{
		Id:           234567,
		Name:         "Wood Table",
		Price:        randomPrice(),
		Category:     "table",
		Discontinued: false,
	}
}

func lamp() Product {
	return Product{
		Id:           345678,
		Name:         "Floor Lamp",
		Price:        randomPrice(),
		Category:     "lamp",
		Discontinued: false,
	}
}

func xbox() Product {
	return Product{
		Id:           720720,
		Name:         "Xbox Series X",
		Price:        randomPrice(),
		Category:     "game console",
		Discontinued: false,
	}
}

func generateRecords(demo string) []Product {
	var records []Product
	switch demo {
	case "name_change":
		c := chair()
		c.Name = "Irregular Chair"
		records = []Product{c, table(), lamp()}
	case "new_product":
		records = []Product{xbox(), table(), lamp()}
	case "three_fiddy":
		c := chair()
		c.Price = "$3.50"
		records = []Product{c, table(), lamp()}
	case "no_results":
		records = []Product{}
	default:
		records = []Product{chair(), table(), lamp()}
	}
	return records
}

func main() {
	router := gin.Default()

	router.GET("/pricing/records.json", func(c *gin.Context) {
		api_key := c.Query("api_key")
		if api_key == "abc123key" {
			start_date := c.Query("start_date")
			end_date := c.Query("end_date")
			demo := c.Query("demo")
			c.JSON(http.StatusOK, gin.H{
				"period_start":   start_date,
				"period_end":     end_date,
				"productRecords": generateRecords(demo)})
		} else {
			c.JSON(http.StatusForbidden, gin.H{})
		}
	})

	router.Run(":8080")
}
