package helpers

import "strings"

func BuildEnum(values []string) (s string) {
	for i := range values {
		values[i] = strings.TrimPrefix(values[i], "/")
	}

	switch len(values) {
	case 0:
		return ""
	case 1:
		return values[0]
	}

	return strings.Join(values[:len(values)-1], ", ") +
		" and " + values[len(values)-1]
}
