package com.sparta.aw.learn_spring_boot;

public record Course(int id, String name, String author) {

    @Override
    public String toString() {
        return "Course{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", author='" + author + '\'' +
                '}';
    }
}
